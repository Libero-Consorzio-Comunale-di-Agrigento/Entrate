--liquibase formatted sql 
--changeset abrandolini:20250326_152423_convalida_docfa stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     CONVALIDA_DOCFA
/*************************************************************************
  Rev.    Date         Author      Note
  7       24/10/2023   AB          Gestito anche il no_data_found nella ricerca
                                   di categorie_catasto e codici_diritto
                                   in modo da proseguire nel caricamento
  6       11/02/2020   VD          Aggiunto controllo su indice array:
                                   se è zero non si lancia l'archiviazione.
  5       13/01/2020   VD          Aggiunta archiviazione denunce inserite
  4       18/10/2019   VD          Corretta composizione estremi catasto:
                                   sostituita RPAD con LPAD
  3       23/10/2017   VD          Soppressione/Variazione:
                                   se non esiste una dichiarazione
                                   precedente, il tr4_oggetto presente
                                   in WRK_DOCFA_OGGETTI veniva annullato.
                                   Ora viene mantenuto l'oggetto originale.
  2       15/03/2017   VD          Aggiunto codice fiscale contribuente
                                   in segnalazioni errore
  1       03/06/2015   PM-VD       Corretta la gestione delle Eccezioni
                                   per tutte le query gestendo sempre il
                                   caso di others
*************************************************************************/
(
  a_documento_id         in     number
 ,a_documento_multi_id   in     number
 ,a_utente               in     varchar2
-- ,a_fonte                in     number
 ,a_messaggio            in out varchar2
)
is
  w_conta_sogg             number;
  w_conta_ogg              number := 0;
  w_errore                 varchar (2000) := null;
  w_sql_errm               varchar (2000) := null;
  w_pratica_inserita       varchar2 (1);
  w_num_pratiche           number;
  w_num_ordine             number;
  errore                   exception;
  w_testata                wrk_docfa_testata%rowtype;
  w_estremi_catasto        oggetti.estremi_catasto%type;
  w_categoria_catasto      oggetti.categoria_catasto%type;
  w_classe_catasto         oggetti.classe_catasto%type;
  w_tipo_oggetto           oggetti_pratica.tipo_oggetto%type;
  w_num_civ                oggetti.num_civ%type;
  w_suffisso               oggetti.suffisso%type;
  w_civico                 wrk_docfa_oggetti.num_civico%type;
  w_dati_oggetto           varchar (2000);
  w_controllo              number;
  w_cod_fiscale            varchar2 (16);
  w_cod_com_nas            number (3);
  w_cod_pro_nas            number (3);
  w_mesi_possesso          oggetti_contribuente.mesi_possesso%type;
  w_flag_possesso          varchar2 (1);
  w_mesi_possesso_1sem     oggetti_contribuente.mesi_possesso_1sem%type;
  w_ogg_prec               wrk_docfa_oggetti%rowtype;
  w_sogg_prec              wrk_docfa_soggetti%rowtype;
  w_perc_possesso_prec     number (5, 2);
  w_tipo_oggetto_prec      number;
  w_categoria_prec         varchar2 (3);
  w_classe_prec            varchar2 (2);
  w_valore_prec            number (15, 2);
  w_titolo_prec            varchar2 (1);
  w_flag_esclusione_prec   varchar2 (1);
  w_flag_ab_princ_prec     varchar2 (1);
  w_detrazione_prec        number (15, 2);
  w_cf_prec                varchar2 (16);
  w_ogpr_prec              number (10);
  w_tipo_tributo           varchar2 (10);
  w_anno_docfa             number(4);
  w_conta                  number;
  w_parametro              installazione_parametri.parametro%type;
  type ty_titr_docfa is table of varchar2(10) index by binary_integer;
  w_titr_docfa             ty_titr_docfa;
  w_pos                    number;
  i                        binary_integer;
  -- (VD - 13/01/2020): Variabili per archiviazione denunce inserite
  type type_pratica is table of pratiche_tributo.pratica%type index by binary_integer;
  t_pratica                type_pratica;
  w_ind                    number := 0;
  procedure inserisce_pratica
  (
    p_tipo_tributo                varchar2
   ,p_data_pratica                date
   ,p_tipo_oggetto                oggetti_pratica.tipo_oggetto%type
   ,p_sogg                 in out wrk_docfa_soggetti%rowtype
   ,p_ogg                  in out wrk_docfa_oggetti%rowtype
   ,p_tes                         wrk_docfa_testata%rowtype
   ,p_flag_possesso               varchar2
   ,p_mesi_possesso               number
   ,p_mesi_possesso_1sem          number
   ,p_titolo                      varchar2
  )
  is
    w_pratica               number;
    w_pratica_esistente     number;
    w_eccezione_caca        varchar2 (1);
    w_eccezione_codi        varchar2 (1);
    w_da_trattare           varchar2 (1);
    w_valore                oggetti_pratica.valore%type;
    w_oggetto_pratica       number;
    w_ogg_cod_via_num_civ   varchar2 (2000);
    w_res_cod_via_num_civ   varchar2 (2000);
    w_flag_ab_principale    varchar2 (1);
    w_detrazione            oggetti_contribuente.detrazione%type;
    w_detrazione_base       oggetti_contribuente.detrazione%type;
    w_mesi_possesso         oggetti_contribuente.mesi_possesso%type
                              := p_mesi_possesso;
    w_mesi_esclusione       oggetti_contribuente.mesi_possesso%type;
    w_flag_esclusione       varchar2 (1);
    w_flag_possesso         varchar2 (1) := p_flag_possesso;
    w_mesi_possesso_1sem    oggetti_contribuente.mesi_possesso_1sem%type
                              := p_mesi_possesso_1sem;
    w_deog_alog_ins         number;
  begin
    -- Recupero dati ECCEZIONE
    w_eccezione_caca := null;
    begin
      select eccezione
        into w_eccezione_caca
        from categorie_catasto
       where categoria_catasto = p_ogg.categoria;
    exception
      when no_data_found then
        w_eccezione_caca := null;
       when others then
        w_errore      :=
             'Errore in estrazione eccezione (CATE) '
          || p_ogg.categoria
          || ' - '
          || p_sogg.codice_fiscale
          || ' ('
          || sqlerrm
          || ')';
        raise errore;
    end;
    if w_eccezione_caca is null then
      if p_sogg.titolo is null then
        w_eccezione_codi := null;
      else
        begin
          select eccezione
            into w_eccezione_codi
            from codici_diritto
           where cod_diritto = upper (p_sogg.titolo);
        exception
      when no_data_found then
        w_eccezione_codi := null;
          when others then
            w_errore      :=
                 'Errore in estrazione eccezione (CODI) '
              || nvl (p_sogg.titolo, 'null')
              || ' prg :'
              || p_ogg.progr_oggetto
              || ' ('
              || sqlerrm
              || ')';
            raise errore;
        end;
      end if;
    end if;
    -- In caso sia settata una eccezione N (NON Trattare)
    -- sulla Categoria Catasto o sul codice_diritto setto la variabile w_da_trattare = 'N'
    -- in questo caso i dati della titolarita non verranno trattati
    if nvl (w_eccezione_caca, w_eccezione_codi) = 'N' then
      w_da_trattare := 'N';
    else
      w_da_trattare := 'S';
    end if;
    if w_da_trattare = 'S' then
      -- Gestione Eccezione di tipo E (Esclusione)
      if nvl (w_eccezione_caca, w_eccezione_codi) = 'E' then
        w_mesi_esclusione    := w_mesi_possesso;
        w_flag_esclusione    := w_flag_possesso;
        w_mesi_possesso_1sem := null;
      else
        w_mesi_esclusione := null;
        w_flag_esclusione := null;
      end if;
      IF p_titolo IN ('A', 'C')
      THEN
         w_valore           :=
          f_valore_da_rendita (p_ogg.rendita
                              ,p_tipo_oggetto
                              ,to_number (to_char (p_data_pratica, 'yyyy'))
                              ,p_ogg.categoria
                              ,'N' -- Immobile Storico
                              );
         BEGIN
            -- cerchiamo se esiste già una pratica identica per contribuente e oggetto
            -- se esiste già non inseriamo il doppione
            SELECT COUNT (1)
              INTO w_pratica_esistente
              FROM oggetti_pratica ogpr,
                   pratiche_tributo prtr,
                   oggetti_contribuente ogco,
                   rapporti_tributo ratr
             WHERE ogpr.pratica = prtr.pratica
               AND ogpr.oggetto_pratica = ogco.oggetto_pratica
               AND prtr.tipo_tributo || '' = p_tipo_tributo
               AND ogpr.oggetto = p_ogg.tr4_oggetto
               AND ogco.cod_fiscale = p_sogg.codice_fiscale
               AND prtr.anno = to_number (to_char (p_data_pratica, 'yyyy'))
               AND prtr.tipo_pratica = 'D'
               AND ogco.mesi_possesso = w_mesi_possesso
               AND ratr.cod_fiscale = prtr.cod_fiscale
               AND ratr.pratica = prtr.pratica
               AND ratr.tipo_rapporto in ('C', 'D', 'E')
               AND NVL (ogco.flag_possesso, 'N') =
                                        NVL (w_flag_possesso, 'N')
               and ogpr.valore = decode (p_ogg.tipo_operazione, 'O', p_ogg.rendita, w_valore)-- se old ho già il valore
               ;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               w_pratica_esistente := 0;
            WHEN OTHERS
            THEN
               w_errore :=
                     'Errore in inserimento Contribuente '
                  || w_cod_fiscale
                  || ' ('
                  || SQLERRM
                  || ')';
               RAISE errore;
         END;
      else
        w_pratica_esistente := 0;
      end if;
      if w_pratica_esistente = 0 then
        w_pratica          := null;
        begin
          select pratica
          into   w_pratica
          from   pratiche_tributo
          where  cod_fiscale = p_sogg.codice_fiscale
          and    tipo_tributo = p_tipo_tributo
          and    anno = to_number (to_char (p_data_pratica, 'yyyy'))
          and    tipo_pratica = 'D'
          and    tipo_evento = 'I'
          and    data = p_data_pratica
          and    documento_id = a_documento_id
          and    documento_multi_id = a_documento_multi_id
          ;
        exception
          when others then w_pratica := null;
        end;
        if w_pratica is null then
          pratiche_tributo_nr (w_pratica);
          w_ind := w_ind + 1;
          t_pratica (w_ind) := w_pratica;
          begin
            insert
              into pratiche_tributo (pratica
                                    ,cod_fiscale
                                    ,tipo_tributo
                                    ,anno
                                    ,tipo_pratica
                                    ,tipo_evento
                                    ,data
                                    ,utente
                                    ,data_variazione
                                    ,note
                                    ,documento_id
                                    ,documento_multi_id
                                    )
            values (w_pratica
                   ,p_sogg.codice_fiscale
                   ,p_tipo_tributo
                   ,to_number (to_char (p_data_pratica, 'yyyy'))
                   ,'D'
                   ,'I'
                   ,p_data_pratica
                   ,a_utente
                   ,trunc (sysdate)
                   ,'Docfa'
                   ,a_documento_id
                   ,a_documento_multi_id
                   );
          exception
            when others then
              w_sql_errm := substr (sqlerrm, 1, 100);
              w_errore      :=
                   'Errore in inserimento nuova pratica '
                || f_descrizione_titr (p_tipo_tributo
                                      ,to_number (to_char (p_data_pratica
                                                          ,'yyyy'
                                                          )
                                                 )
                                      )
                || ' ('
                || w_sql_errm
                || ')';
              raise errore;
          end;
          w_pratica_inserita := 'S';
          w_num_pratiche     := w_num_pratiche + 1;
          w_num_ordine       := 1;
          -- se la pratica viene inserita devo settare le variabili che indicano
          -- la cancellazione finale del soggetto/contribuente a 'N' in modo che non venga cancellato
          --    w_cancella_contribuente := 'N';
          --    w_canella_soggetto      := 'N';
          begin
            insert into rapporti_tributo (pratica, cod_fiscale, tipo_rapporto)
                 values (w_pratica, p_sogg.codice_fiscale, 'D');
          exception
            when others then
              w_sql_errm := substr (sqlerrm, 1, 100);
              w_errore      :=
                   'Errore in inserimento rapporto tributo '
                || f_descrizione_titr (p_tipo_tributo
                                      ,to_number (to_char (p_data_pratica
                                                          ,'yyyy'
                                                          )
                                                 )
                                      )
                || ' ('
                || w_sql_errm
                || ')';
              raise errore;
          end;
          if p_tipo_tributo = 'ICI' then
            begin
              insert
                into denunce_ici (pratica
                                 ,denuncia
                                 ,fonte
                                 ,utente
                                 ,data_variazione
                                 )
              values (w_pratica, w_pratica, p_tes.fonte, a_utente, trunc (sysdate));
            exception
              when others then
                w_sql_errm := substr (sqlerrm, 1, 100);
                w_errore      :=
                     'Errore in inserimento denunce_ici '
                  || ' ('
                  || w_sql_errm
                  || ')';
                raise errore;
            end;
          else
            begin
              insert
                into denunce_tasi (pratica
                                  ,denuncia
                                  ,fonte
                                  ,utente
                                  ,data_variazione
                                  )
              values (w_pratica, w_pratica, p_tes.fonte, a_utente, trunc (sysdate));
            exception
              when others then
                w_sql_errm := substr (sqlerrm, 1, 100);
                w_errore      :=
                     'Errore in inserimento denunce_tasi '
                  || ' ('
                  || w_sql_errm
                  || ')';
                raise errore;
            end;
          end if;
        end if;
        w_oggetto_pratica  := null;
        oggetti_pratica_nr (w_oggetto_pratica);
        begin
          insert
            into oggetti_pratica (oggetto_pratica
                                 ,oggetto
                                 ,tipo_oggetto
                                 ,pratica
                                 ,anno
                                 ,num_ordine
                                 ,categoria_catasto
                                 ,classe_catasto
                                 ,valore
                                 ,flag_valore_rivalutato
                                 ,titolo
                                 ,fonte
                                 ,utente
                                 ,data_variazione
                                 )
          values (w_oggetto_pratica
                 ,p_ogg.tr4_oggetto
                 ,p_tipo_oggetto
                 ,w_pratica
                 ,to_number (to_char (p_data_pratica, 'yyyy'))
                 ,to_char (w_num_ordine)
                 ,p_ogg.categoria
                 ,p_ogg.classe
                 ,decode (p_ogg.tipo_operazione, 'O', p_ogg.rendita, w_valore) -- se old ho già il valore
                 ,decode (sign (  1996
                                - to_number (to_char (p_data_pratica, 'yyyy'))
                               )
                         ,-1, 'S'
                         ,''
                         )
                 ,p_titolo
                 ,p_tes.fonte
                 ,a_utente
                 ,trunc (sysdate)
                 );
        exception
          when others then
            w_sql_errm := substr (sqlerrm, 1, 100);
            w_errore      :=
                 'Errore in inserimento oggetti_pratica '
              || f_descrizione_titr (p_tipo_tributo
                                    ,to_number (to_char (p_data_pratica
                                                        ,'yyyy'
                                                        )
                                               )
                                    )
              || ' ('
              || w_sql_errm
              || ')';
            raise errore;
        end;
        --      w_num_nuovi_ogpr  := w_num_nuovi_ogpr + 1;
        w_num_ordine       := w_num_ordine + 1;
        -- Recupero Flag Abitazione Principale
        if p_sogg.titolo = 'A'
       and substr (p_ogg.categoria, 1, 1) in ('A', 'C') then
          begin
            select    nvl (lpad (ogge.cod_via, 6, '0'), 'xxxxxx')
                   || nvl (lpad (ogge.num_civ, 6, '0'), 'xxxxxx')
              into w_ogg_cod_via_num_civ
              from oggetti ogge
             where ogge.oggetto = p_ogg.tr4_oggetto;
          exception
            when others then
              w_sql_errm := substr (sqlerrm, 1, 100);
              w_errore      :=
                   'Errore in recupero indirizzo oggetto '
                || to_char (p_ogg.tr4_oggetto)
                || f_descrizione_titr (p_tipo_tributo
                                      ,to_number (to_char (p_data_pratica
                                                          ,'yyyy'
                                                          )
                                                 )
                                      )
                || ' ('
                || w_sql_errm
                || ')';
              raise errore;
          end;
          -- Recupero Indirizzo residenza
          begin
             w_res_cod_via_num_civ      :=
               f_indirizzo_ni_al (p_sogg.tr4_ni
                                 ,to_date (   '3112'
                                           || to_char (to_number (to_char (p_data_pratica
                                                                          ,'yyyy'
                                                                          )
                                                                 )
                                                      )
                                          ,'ddmmyyyy'
                                          )
                                 );
          exception
            when others then
               w_errore      :=
                   'Errore in  f_indirizzo_ni_al';
          end;
          if w_ogg_cod_via_num_civ = w_res_cod_via_num_civ then
            w_flag_ab_principale := 'S';
            if substr (p_ogg.categoria, 1, 1) = 'A'
           and nvl (p_sogg.perc_possesso, 0) = 100 then
              w_detrazione      :=
                round (w_detrazione_base / 12 * w_mesi_possesso, 2);
            else
              w_detrazione := null;
            end if;
          else
            w_flag_ab_principale := null;
            w_detrazione         := null;
          end if;
        else
          w_flag_ab_principale := null;
          w_detrazione         := null;
        end if;
        -- Gestione Eccezione di tipo E (Esclusione)
        if nvl (w_eccezione_caca, w_eccezione_codi) = 'E' then
          w_mesi_esclusione    := w_mesi_possesso;
          w_flag_esclusione    := w_flag_possesso;
          w_mesi_possesso_1sem := null;
        else
          w_mesi_esclusione := null;
          w_flag_esclusione := null;
        end if;
        begin
          insert
            into oggetti_contribuente (cod_fiscale
                                      ,oggetto_pratica
                                      ,anno
                                      ,tipo_rapporto
                                      ,perc_possesso
                                      ,mesi_possesso
                                      ,mesi_possesso_1sem
                                      ,mesi_esclusione
                                      ,flag_possesso
                                      ,flag_esclusione
                                      ,flag_ab_principale
                                      ,detrazione
                                      ,utente
                                      ,data_variazione
                                      ,perc_detrazione
                                      )
          values (p_sogg.codice_fiscale
                 ,w_oggetto_pratica
                 ,to_number (to_char (p_data_pratica, 'yyyy'))
                 ,'D'
                 ,p_sogg.perc_possesso
                 ,w_mesi_possesso --
                 ,w_mesi_possesso_1sem --
                 ,w_mesi_esclusione
                 ,w_flag_possesso --
                 ,w_flag_esclusione
                 ,w_flag_ab_principale
                 ,w_detrazione
                 ,a_utente
                 ,trunc (sysdate)
                 ,decode (w_detrazione, null, null, 100)
                 );
        exception
          when others then
            w_sql_errm := substr (sqlerrm, 1, 100);
            w_errore      :=
                 'Errore in inserim. oggetti_contribuente '
              || f_descrizione_titr (p_tipo_tributo
                                    ,to_number (to_char (p_data_pratica
                                                        ,'yyyy'
                                                        )
                                               )
                                    )
              || ' ('
              || w_sql_errm
              || ')';
            raise errore;
        end;
        -- Gestione Deog Alog
        --      w_deog_alog_ins   := 0;
        --      inserisci_deog_alog (p_sogg.codice_fiscale
        --                          ,w_oggetto_pratica
        --                          ,to_number (to_char (p_data_pratica, 'yyyy'))
        --                          ,w_cf_prec
        --                          ,w_ogpr_prec
        --                          ,w_deog_alog_ins
        --                          );
        --
        --      -- Nel caso di presenza di deog o alog vengono messi a null sia
        --      -- il flag_ab_princiaple che la detrazione
        --      if w_deog_alog_ins > 0 then
        --        begin
        --          update oggetti_contribuente
        --             set flag_ab_principale = null, detrazione = null
        --           where cod_fiscale = w_cod_fiscale
        --             and oggetto_pratica = w_oggetto_pratica;
        --        exception
        --          when others then
        --            sql_errm := substr (sqlerrm, 1, 100);
        --            w_errore      :=
        --                 'Errore update ogco, annullamento ab_principale e detrazione '
        --              || f_descrizione_titr (a_tipo_tributo
        --                                    ,to_number (to_char (p_data_pratica
        --                                                        ,'yyyy'
        --                                                        )
        --                                               )
        --                                    )
        --              || ' ('
        --              || sql_errm
        --              || ')';
        --            raise errore;
        --        end;
        --      end if;
        begin
          insert
            into attributi_ogco (cod_fiscale
                                ,oggetto_pratica
                                ,data_reg_atti
                                ,rogante
                                ,cod_fiscale_rogante
                                ,sede_rogante
                                ,data_validita_atto
                                ,utente
                                ,data_variazione
                                ,note
                                )
          values (p_sogg.codice_fiscale
                 ,w_oggetto_pratica
                 ,p_data_pratica
                 ,p_tes.cognome_tec || ' ' || p_tes.nome_tec
                 ,p_tes.cod_fiscale_tec
                 ,p_tes.prov_iscrizione_tec
                 ,p_data_pratica
                 ,a_utente
                 ,trunc (sysdate)
                 ,''
                 );
        exception
          when others then
            w_sql_errm := substr (sqlerrm, 1, 100);
            w_errore      :=
                 'Errore in inserim. oggetti_contribuente '
              || f_descrizione_titr (p_tipo_tributo
                                    ,to_number (to_char (p_data_pratica
                                                        ,'yyyy'
                                                        )
                                               )
                                    )
              || ' ('
              || w_sql_errm
              || ')';
            raise errore;
        end;
      end if; --pratica esistente
    end if;
  exception
    when errore then
      rollback;
      raise_application_error (-20999, 'inserisce_pratica '||nvl (w_errore, 'vuoto'));
    when others then
      raise_application_error
                               (-20999,
                                   'Errore in inserisce_pratica ('
                                || SQLERRM
                                || ')'
                               );
  end inserisce_pratica;
--  procedure inserisci_deog_alog
--  (
--    p_cod_fiscale       in     varchar2
--   ,p_oggetto_pratica   in     number
--   ,p_anno_denuncia     in     number
--   ,p_cf_prec           in     varchar2
--   ,p_ogpr_prec         in     number
--   ,p_deog_alog_ins        out number
--  )
--  is
--    w_conta_deog   number;
--    w_conta_alog   number;
--  begin
--    -- DEOG
--    begin
--      insert into detrazioni_ogco (cod_fiscale
--                                  ,oggetto_pratica
--                                  ,anno
--                                  ,motivo_detrazione
--                                  ,detrazione
--                                  ,note
--                                  ,detrazione_acconto
--                                  ,tipo_tributo
--                                  )
--        (select p_cod_fiscale
--               ,p_oggetto_pratica
--               ,p_anno_denuncia
--               ,motivo_detrazione
--               ,detrazione
--               ,note
--               ,detrazione_acconto
--               ,tipo_tributo
--           from detrazioni_ogco
--          where cod_fiscale = p_cf_prec
--            and oggetto_pratica = p_ogpr_prec
--            and anno = p_anno_denuncia
--            and tipo_tributo = a_tipo_tributo);
--    end;
--
--    -- ALOG
--    begin
--      insert into aliquote_ogco (cod_fiscale
--                                ,oggetto_pratica
--                                ,dal
--                                ,al
--                                ,tipo_aliquota
--                                ,note
--                                ,tipo_tributo
--                                )
--        (select p_cod_fiscale
--               ,p_oggetto_pratica
--               ,dal
--               ,al
--               ,tipo_aliquota
--               ,note
--               ,tipo_tributo
--           from aliquote_ogco
--          where cod_fiscale = p_cf_prec
--            and oggetto_pratica = p_ogpr_prec
--            and tipo_tributo = a_tipo_tributo
--            and p_anno_denuncia between to_number (to_char (dal, 'yyyy'))
--                                    and nvl (to_number (to_char (al, 'yyyy'))
--                                            ,9999
--                                            ));
--    end;
--
--    begin
--      select count (1)
--        into w_conta_deog
--        from detrazioni_ogco
--       where oggetto_pratica = p_oggetto_pratica
--         and cod_fiscale = p_cod_fiscale
--         and tipo_tributo = a_tipo_tributo;
--    exception
--      when others then
--        w_conta_deog := 0;
--    end;
--
--    begin
--      select count (1)
--        into w_conta_alog
--        from aliquote_ogco
--       where oggetto_pratica = p_oggetto_pratica
--         and cod_fiscale = p_cod_fiscale
--         and tipo_tributo = a_tipo_tributo;
--    exception
--      when others then
--        w_conta_alog := 0;
--    end;
--
--    p_deog_alog_ins := nvl (w_conta_deog, 0) + nvl (w_conta_alog, 0);
--  exception
--    when others then
--      null;
--  end inserisci_deog_alog;
begin
   a_messaggio := null;
   BEGIN
      SELECT nvl(TRIM (UPPER (valore)),'ICI')
        INTO w_parametro
        FROM installazione_parametri
       WHERE parametro = 'TITR_DOCFA';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         w_parametro := 'ICI';
      WHEN OTHERS
      THEN
         raise_application_error
                               (-20999,
                                   'Errore in lettura parametro TITR_DOCFA ('
                                || SQLERRM
                                || ')'
                               );
   END;
   i := 0;
   begin
      select to_char(data_realizzazione,'yyyy')
      into   w_anno_docfa
      from   wrk_docfa_testata
      where  documento_id = a_documento_id
      and    documento_multi_id = a_documento_multi_id
      ;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error
                               (-20999,
                                   'Errore in lettura wrk_docfa_testata ('
                                || SQLERRM
                                || ')'
                               );
   end;
   WHILE w_parametro IS NOT NULL
   LOOP
      w_conta_ogg := 1;
      w_pos := NVL (INSTR (w_parametro, ' '), 0);
      IF w_pos = 0
      THEN
         w_tipo_tributo := w_parametro;
         w_parametro := NULL;
      ELSE
         w_tipo_tributo := SUBSTR (w_parametro, 1, w_pos - 1);
      END IF;
      IF w_pos < LENGTH (w_parametro) AND w_pos > 0
      THEN
         w_parametro := SUBSTR (w_parametro, w_pos + 1);
      ELSE
         w_parametro := NULL;
      END IF;
      if w_tipo_tributo = 'TASI' and w_anno_docfa <= 2013 then
        null;
      else w_titr_docfa(i) := w_tipo_tributo;
           i := i +1;
      end if;
   end loop;
   if i = 0 then
      w_errore      :=
          'Non esiste il tipo tributo da trattare oppure tipo tributo incompatibile con l''anno';
        raise errore;
   end if;
   w_conta_ogg := 0;
   for w_ogg in (select *
                   from wrk_docfa_oggetti
                  where documento_id = a_documento_id
                    and documento_multi_id = a_documento_multi_id) loop
     begin
       w_conta_ogg := w_conta_ogg + 1;
       select count (*)
         into w_conta_sogg
         from wrk_docfa_soggetti wrds
        where documento_id = a_documento_id
          and documento_multi_id = a_documento_multi_id
          and wrds.progr_oggetto = w_ogg.progr_oggetto;
       if w_conta_sogg = 0 then
         w_errore      :=
           'Mancano i soggetti per l''oggetto prg' || w_ogg.progr_oggetto;
         raise errore;
       end if;
     end;
   end loop;

  if w_conta_ogg > 0 then -- abbiamo gli oggetti ed i contribuenti
    begin
      select *
        into w_testata
        from wrk_docfa_testata
       where documento_id = a_documento_id
         and documento_multi_id = a_documento_multi_id;
    exception
      when others then
        w_errore := 'Errore in lettura testata ' || sqlerrm;
        raise errore;
    end;
    for w_ogg in (select *
                    from wrk_docfa_oggetti
                   where documento_id = a_documento_id
                     and documento_multi_id = a_documento_multi_id) loop
      --      w_ogg.tr4_oggetto := 0;
      if w_ogg.tr4_oggetto is null then
        if w_ogg.sezione || w_ogg.foglio || w_ogg.numero || w_ogg.subalterno
             is not null then
          w_estremi_catasto      :=
               lpad (ltrim (nvl (w_ogg.sezione, ' '), '0'), 3, ' ')
            || lpad (ltrim (nvl (w_ogg.foglio, ' '), '0'), 5, ' ')
            || lpad (ltrim (nvl (w_ogg.numero, ' '), '0'), 5, ' ')
            || lpad (ltrim (nvl (w_ogg.subalterno, ' '), '0'), 4, ' ')
            || lpad (' ', 3);
          begin
            select oggetto
                 , tipo_oggetto
                 , classe_catasto
                 , categoria_catasto
              into w_ogg.tr4_oggetto
                 , w_tipo_oggetto
                 , w_classe_catasto
                 , w_categoria_catasto
              from oggetti
             where oggetto =
                     (select max (oggetto)
                        from oggetti ogge
                       where ogge.tipo_oggetto + 0 in (3, 4, 55)
                         and ogge.estremi_catasto = w_estremi_catasto
                         and nvl (substr (ogge.categoria_catasto,1,1),' ')
                             = nvl (substr (w_ogg.categoria, 1, 1),
                                    nvl (substr (ogge.categoria_catasto,1,1),' ')))
            ;
          exception
            when no_data_found then
              w_ogg.tr4_oggetto   := null;
              w_tipo_oggetto      := null;
              w_classe_catasto    := null;
              w_categoria_catasto := null;
            when others then
              w_sql_errm := substr (sqlerrm, 1, 100);
              w_errore      :=
                   'Errore in controllo esistenza fabbricato'
                || ' ('
                || w_sql_errm
                || ')';
              raise errore;
          end;
        end if;
      else
        begin
          select tipo_oggetto
               , classe_catasto
               , categoria_catasto
            into w_tipo_oggetto
               , w_classe_catasto
               , w_categoria_catasto
            from oggetti
           where oggetto = w_ogg.tr4_oggetto;
        exception
          when others then
            w_sql_errm := substr (sqlerrm, 1, 100);
            w_errore      :=
              'Errore in ricerca fabbricato' || ' (' || w_sql_errm || ')';
            raise errore;
        end;
      end if;

      if nvl (w_ogg.tr4_oggetto, 0) = 0 then -- Oggetto non trovato
        begin
          select cod_via
            into w_ogg.cod_via
            from denominazioni_via devi
           where UPPER(w_ogg.indirizzo) like
                   chr (37) || UPPER(devi.descrizione) || chr (37)
             and devi.descrizione is not null
             and not exists
                       (select 'x'
                          from denominazioni_via devi1
                         where UPPER(w_ogg.indirizzo) like
                                 chr (37) || UPPER(devi1.descrizione) || chr (37)
                           and devi1.descrizione is not null
                           and devi1.cod_via != devi.cod_via)
             and rownum = 1;
        exception
          when no_data_found then
            w_ogg.cod_via := 0;
          when others then
            w_sql_errm := substr (sqlerrm, 1, 100);
            w_errore      :=
                 'Errore in controllo esistenza indirizzo fabbricato'
              || 'indir: '
              || w_ogg.indirizzo
              || ' ('
              || w_sql_errm
              || ')';
            raise errore;
        end;
        if w_ogg.num_civico is null then
          w_num_civ  := null;
          w_suffisso := null;
        else
          w_civico := translate (w_ogg.num_civico, '/-', '//');
          --DBMS_OUTPUT.Put_Line('w_civico: '||w_civico);
          if translate (nvl (w_civico, ' '), 'a0123456789', 'a') is null then
            w_num_civ  := to_number (w_civico);
            w_suffisso := null;
          else
            -- Verifica di errore per Civico non numerico
            if translate (substr (w_civico, 1, instr (w_civico, '/') - 1)
                         ,'-0123456789/'
                         ,'-'
                         )
                 is not null
            or instr (w_civico, '/') < 1 then
              -- Se il numero civico non è un numerico inserisco num_civ e suffisso nulli
              -- e una anomalia per l'oggetto con il dato del numero civico errato
              w_dati_oggetto := 'Numero Civico : ' || w_ogg.num_civico;
              w_num_civ      := null;
              w_suffisso     := null;
            else
              w_num_civ      :=
                to_number (substr (w_civico, 1, instr (w_civico, '/') - 1));
              w_suffisso      :=
                ltrim (substr (w_civico, instr (w_civico, '/') + 1));
            end if;
          end if;
        end if;
        if w_ogg.categoria is not null then
          begin
            select count (1)
              into w_controllo
              from categorie_catasto
             where categoria_catasto = w_ogg.categoria;
          exception
            when others then
              w_sql_errm := substr (sqlerrm, 1, 100);
              w_errore      :=
                   'Errore in ricerca Categorie Catasto'
                || ' ('
                || w_sql_errm
                || ')';
              raise errore;
          end;
          if nvl (w_controllo, 0) = 0 then
            begin
              insert into categorie_catasto (categoria_catasto, descrizione)
                   values (w_ogg.categoria, 'DA CARICAMENTO DATI DOCFA');
            exception
              when others then
                w_sql_errm := substr (sqlerrm, 1, 100);
                w_errore      :=
                     'Errore in inserimento Categorie Catasto'
                  || ' ('
                  || w_sql_errm
                  || ')';
                raise errore;
            end;
          end if;
        end if; -- fine controllo categoria not null

        w_ogg.tr4_oggetto := null;
        oggetti_nr (w_ogg.tr4_oggetto);
        begin
          insert
            into oggetti (oggetto
                         ,tipo_oggetto
                         ,indirizzo_localita
                         ,cod_via
                         ,num_civ
                         ,suffisso
                         ,sezione
                         ,foglio
                         ,numero
                         ,subalterno
                         ,categoria_catasto
                         ,classe_catasto
                         ,fonte
                         ,utente
                         ,data_variazione
                         )
          values (w_ogg.tr4_oggetto
                 ,3
                 ,decode (w_ogg.cod_via
                         ,0, substr (w_ogg.indirizzo, 1, 36)
                         ,''
                         )
                 ,decode (w_ogg.cod_via, 0, null, w_ogg.cod_via)
                 ,w_num_civ
                 ,w_suffisso
                 ,w_ogg.sezione
                 ,w_ogg.foglio
                 ,w_ogg.numero
                 ,w_ogg.subalterno
                 ,w_ogg.categoria
                 ,w_ogg.classe
                 ,w_testata.fonte
                 ,a_utente
                 ,trunc (sysdate)
                 );
          w_tipo_oggetto      := 3;
          w_classe_catasto    := w_ogg.classe;
          w_categoria_catasto := w_ogg.categoria;
        exception
          when others then
            w_sql_errm := substr (sqlerrm, 1, 100);
            w_errore      :=
                 'Errore in inserimento fabbricato '
              || ' ('
              || w_sql_errm
              || ')';
            raise errore;
        end;
        if w_dati_oggetto is not null then
          -- Inserimento Anomalia Caricamento Oggetto
          begin
            insert
              into anomalie_caricamento (documento_id
                                        ,oggetto
                                        ,descrizione
                                        ,dati_oggetto
                                        ,note
                                        )
            values (a_documento_id
                   ,w_ogg.tr4_oggetto
                   ,'Numero Civico non Numerico'
                   ,w_dati_oggetto
                   ,null
                   );
          exception
            when others then
              w_errore      :=
                   'Errore in inserimento anomalie_caricamento oggetto: '
                || to_char (w_ogg.tr4_oggetto)
                || ' ('
                || sqlerrm
                || ')';
              raise errore;
          end;
          --          w_num_oggetti_anomali := w_num_oggetti_anomali + 1;
          w_dati_oggetto := null;
        end if;
      --        w_num_nuovi_oggetti := w_num_nuovi_oggetti + 1;
      end if; -- fine controllo se immobile gia' presente
      --        if nvl(w_ogg.oggetto,0) != 0 then
      --           update wrk_docfa_oggetti
      --              set oggetto = w_ogg.oggetto
      --            where documento_id = a_documento_id
      --              and documento_multi_id = a_documento_multi_id
      --              and prg_oggetto = w_ogg.prg_oggetto
      --           ;
      --        end if;

      -- inserimento soggetti
      for w_sogg in (select *
                       from wrk_docfa_soggetti
                      where documento_id = a_documento_id
                        and documento_multi_id = a_documento_multi_id
                        and progr_oggetto = w_ogg.progr_oggetto) loop


        w_sogg.tr4_ni := 0;
        --        w_anomalia_cont         := 'N';
        --        w_ni                    := null;
        w_cod_fiscale := null;
        -- Le seguente variabili indicano se cancellare il contribunete e/o il soggetto dopo il trattamento,
        -- questo nel caso non venga creata la pratica per il contribuente (Eccezione: NON Trattare)
        -- e solo se non era già soggetto e/o contribuente precedentemente
        --        w_cancella_contribuente := 'N';
        --        w_cancella_soggetto     := 'N';
        if w_sogg.codice_fiscale is null then
          -- Inserimento Anomalia Caricamento Contribuente
          begin
            insert
              into anomalie_caricamento (documento_id
                                        ,cognome
                                        ,descrizione
                                        ,note
                                        )
            values (a_documento_id
                   ,substr (w_sogg.denominazione, 1, 60)
                   ,'Codice Fiscale Nullo'
                   ,null
                   );
          exception
            when others then
              w_errore      :=
                   'Errore in inserimento anomalie_contribuente '
                || substr (w_sogg.denominazione, 1, 60)
                || ' ('
                || sqlerrm
                || ')';
              raise errore;
          end;
        --          w_anomalia_cont := 'S';
        else
          begin
            select cont.cod_fiscale
              into w_cod_fiscale
              from contribuenti cont
             where cont.cod_fiscale = w_sogg.codice_fiscale;
          exception
            when no_data_found then
              w_cod_fiscale := null;
            when others then
              w_errore      :=
                   'Errore in verifica Codice Fiscale per '
                || w_sogg.codice_fiscale
                || ' ('
                || sqlerrm
                || ')';
              raise errore;
          end;
        end if;


        -- DBMS_OUTPUT.Put_Line('w_cod_fiscale: '||nvl(w_cod_fiscale,'(Nullo)'));
        if w_cod_fiscale is null then -- Contribuente non trovato
          --       and w_anomalia_cont = 'N' then -- serve??
          -- Verifica del soggetto
          if length (w_sogg.codice_fiscale) = 11 then
            begin
              w_sogg.cognome := null;
              w_sogg.nome    := null;
              w_sogg.tipo    := 1; -- persona giuridica
              select sogg.ni
                into w_sogg.tr4_ni
                from soggetti sogg
               where nvl (sogg.partita_iva, sogg.cod_fiscale) =
                       w_sogg.codice_fiscale
                 and sogg.cognome = w_sogg.denominazione;
            exception
              when no_data_found then
                w_sogg.tr4_ni := null;
              when others then
                w_errore      :=
                     'Errore in verifica Partita IVA (1) per '
                  || w_sogg.codice_fiscale
                  || ' ('
                  || sqlerrm
                  || ')';
                raise errore;
            end;
          else
            begin
              if w_sogg.cognome is null or w_sogg.nome is null
              then w_sogg.cognome       := rtrim (substr (w_sogg.denominazione, 1, 50));
                   w_sogg.nome          := rtrim (substr (w_sogg.denominazione, 51,36));
                   w_sogg.denominazione := w_sogg.cognome || '/' || w_sogg.nome;
              end if;
              w_sogg.tipo          := 0; -- persona fisica
              select sogg.ni
                into w_sogg.tr4_ni
                from soggetti sogg
               where sogg.cod_fiscale = w_sogg.codice_fiscale
                 and sogg.cognome = w_sogg.cognome;
            exception
              when no_data_found then
                w_sogg.tr4_ni := null;
              when others then
                w_errore      :=
                     'Errore in ricerca soggetto per '
                  || w_sogg.codice_fiscale
                  || ' ('
                  || sqlerrm
                  || ')';
                raise errore;
            end;
          end if;
          -- DBMS_OUTPUT.Put_Line('w_ni: '||to_char(nvl(w_ni,-9999)));
          if w_sogg.tr4_ni is null then
            -- Inserimento Nuovo Soggetto
            --            w_cancella_soggetto  := 'S'; --serve??
            -- il soggetto verrà cancellato se la pratica risulterà non trattata (nessun ogpr da trattare)
            begin
              select comune, provincia_stato
                into w_cod_com_nas, w_cod_pro_nas
                from ad4_comuni
               where denominazione = w_sogg.comune_nascita;
            exception
              when others then
                w_cod_com_nas := null;
                w_cod_pro_nas := null;
            end;
            soggetti_nr (w_sogg.tr4_ni);
            begin
              insert
                into soggetti (ni
                              ,tipo_residente
                              ,cod_fiscale
                              ,cognome_nome
                              ,data_nas
                              ,cod_com_nas
                              ,cod_pro_nas
                              ,sesso
                              ,tipo
                              ,fonte
                              ,utente
                              ,data_variazione
                              )
              values (w_sogg.tr4_ni
                     ,1
                     ,w_sogg.codice_fiscale
                     ,substr (w_sogg.denominazione, 1, 60)
                     ,w_sogg.data_nascita
                     ,w_cod_com_nas
                     ,w_cod_pro_nas
                     ,w_sogg.sesso
                     ,w_sogg.tipo
                     ,w_testata.fonte
                     ,a_utente
                     ,trunc (sysdate)
                     );
            exception
              when others then
                w_errore      :=
                     'Errore in inserimento Soggetto '
                  || w_sogg.codice_fiscale
                  || ' ('
                  || sqlerrm
                  || ')';
                raise errore;
            end;
            --            w_num_nuovi_soggetti := w_num_nuovi_soggetti + 1;
            w_cod_fiscale := w_sogg.codice_fiscale;
          -- DBMS_OUTPUT.Put_Line('CF_PF: '||w_cod_fiscale);
          else --w_ni  is not null
            w_cod_fiscale := w_sogg.codice_fiscale;
          -- DBMS_OUTPUT.Put_Line('CF_trovato: '||w_cod_fiscale);
          end if;
          -- Inserimento Contribuente
          --          w_cancella_contribuente  := 'S'; --Serve??
          if w_cod_fiscale is not null then
            w_sogg.codice_fiscale := w_cod_fiscale;
          end if;
        -- il contribuente verrà cancellato se la pratica risulterà non trattata (nessun ogpr trattato)
        --          w_num_nuovi_contribuenti := w_num_nuovi_contribuenti + 1;
        --        elsif w_anomalia_cont = 'N' then -- esiste il soggetto, ma non il contribuente
        --          -- Inserimento Contribuente
        ----          w_cancella_contribuente  := 'S'; --Serve??
        --
        --          -- il contribuente verrà cancellato se la pratica risulterà non trattata (nessun ogpr trattato)
        --
        --          begin
        --            insert into contribuenti (cod_fiscale, ni)
        --                 values (w_cod_fiscale, w_sogg.tr4_ni);
        --          exception
        --            when others then
        --              w_errore      :=
        --                   'Errore in inserimento Contribuente '
        --                || w_cod_fiscale
        --                || ' ('
        --                || sqlerrm
        --                || ')';
        --              raise errore;
        --          end;
        --
        --          w_num_nuovi_contribuenti := w_num_nuovi_contribuenti + 1;
        end if; -- if w_cod_fiscale is null and w_anomalia_cont = 'N'

        begin
          insert into contribuenti (cod_fiscale, ni)
            select w_sogg.codice_fiscale, w_sogg.tr4_ni
              from dual
             where not exists
                         (select 'x'
                            from contribuenti
                           where contribuenti.cod_fiscale =
                                   w_sogg.codice_fiscale);
        exception
          when others then
            w_errore      :=
                 'Errore in inserimento Contribuente '
              || w_cod_fiscale
              || ' ('
              || sqlerrm
              || ')';
            raise errore;
        end;



        for i in w_titr_docfa.first .. w_titr_docfa.last loop


            w_tipo_tributo := w_titr_docfa(i);


          if w_ogg.tipo_operazione in ('S', 'V') then -- soppressione o variazione
            begin
              select w_ogg.documento_id
                    ,w_ogg.documento_multi_id
                    ,w_ogg.progr_oggetto
                    ,'O'
                    ,w_ogg.sezione
                    ,w_ogg.foglio
                    ,w_ogg.numero
                    ,w_ogg.subalterno
                    ,w_ogg.cod_via
                    ,w_ogg.indirizzo
                    ,w_ogg.num_civico
                    ,w_ogg.piano
                    ,w_ogg.scala
                    ,w_ogg.interno
                    ,w_ogg.zona
                    ,nvl(ogpr.categoria_catasto,w_categoria_catasto)
                    ,nvl(ogpr.classe_catasto,w_classe_catasto)
                    ,w_ogg.consistenza
                    ,w_ogg.superficie_catastale
                    ,f_valore(ogpr.valore, ogpr.tipo_oggetto, prtr.anno
                            , to_char(w_testata.data_realizzazione,'yyyy')
                            , ogpr.categoria_catasto, prtr.tipo_pratica
                            , ogpr.flag_valore_rivalutato) valore
                    ,ogpr.oggetto
                    ,ogpr.titolo
                    ,ogco.flag_esclusione
                    ,ogco.flag_ab_principale
                    ,ogco.cod_fiscale
                    ,ogco.oggetto_pratica
                    ,ogco.perc_possesso
                    ,ogpr.tipo_oggetto
                into w_ogg_prec.documento_id
                    ,w_ogg_prec.documento_multi_id
                    ,w_ogg_prec.progr_oggetto
                    ,w_ogg_prec.tipo_operazione
                    ,w_ogg_prec.sezione
                    ,w_ogg_prec.foglio
                    ,w_ogg_prec.numero
                    ,w_ogg_prec.subalterno
                    ,w_ogg_prec.cod_via
                    ,w_ogg_prec.indirizzo
                    ,w_ogg_prec.num_civico
                    ,w_ogg_prec.piano
                    ,w_ogg_prec.scala
                    ,w_ogg_prec.interno
                    ,w_ogg_prec.zona
                    ,w_ogg_prec.categoria
                    ,w_ogg_prec.classe
                    ,w_ogg_prec.consistenza
                    ,w_ogg_prec.superficie_catastale
                    ,w_ogg_prec.rendita
                    ,w_ogg_prec.tr4_oggetto
                    ,w_titolo_prec
                    ,w_flag_esclusione_prec
                    ,w_flag_ab_princ_prec
                    ,w_cf_prec
                    ,w_ogpr_prec
                    ,w_perc_possesso_prec
                    ,w_tipo_oggetto_prec
                from pratiche_tributo prtr
                    ,oggetti_pratica ogpr
                    ,oggetti_contribuente ogco
               where ogco.oggetto_pratica = ogpr.oggetto_pratica
                 and ogpr.pratica = prtr.pratica
                 and ogco.cod_fiscale = w_sogg.codice_fiscale
                 and ogpr.oggetto = w_ogg.tr4_oggetto
                 and ogco.flag_possesso = 'S'
                 and prtr.tipo_tributo || '' = w_tipo_tributo
                 and (ogco.anno || ogco.tipo_rapporto || 'S') =
                       (select max (   ogco_sub.anno
                                    || ogco_sub.tipo_rapporto
                                    || ogco_sub.flag_possesso
                                   )
                          from pratiche_tributo prtr_sub
                              ,oggetti_pratica ogpr_sub
                              ,oggetti_contribuente ogco_sub
                         where prtr_sub.tipo_tributo || '' = w_tipo_tributo
                           and ( (prtr_sub.tipo_pratica || '' = 'D'
                              and prtr_sub.data_notifica is null)
                             or (prtr_sub.tipo_pratica || '' = 'A'
                             and prtr_sub.data_notifica is not null
                             and nvl (prtr_sub.stato_accertamento, 'D') = 'D'
                             and nvl (prtr_sub.flag_denuncia, ' ') = 'S'
                             and prtr_sub.anno <=
                                   to_char (w_testata.data_realizzazione
                                           ,'yyyy'
                                           )))
                           and prtr_sub.pratica = ogpr_sub.pratica
                           and ogco_sub.anno <=
                                 to_char (w_testata.data_realizzazione
                                         ,'yyyy'
                                         )
                           and ogco_sub.cod_fiscale = ogco.cod_fiscale
                           and ogco_sub.oggetto_pratica =
                                 ogpr_sub.oggetto_pratica
                           and ogpr_sub.oggetto = ogpr.oggetto
                           and ogco_sub.tipo_rapporto in ('C', 'D', 'E')
                           and nvl (ogco_sub.flag_possesso, 'N') =
                                 decode (w_tipo_tributo
                                        ,'TASI', 'S'
                                        ,nvl (ogco_sub.flag_possesso, 'N')
                                        ));
            exception
              when no_data_found then
                begin
--                  dbms_output.put_line('CF '||w_sogg.codice_fiscale||
--                                          ' Anno '||to_char (w_testata.data_realizzazione,'yyyy')||
--                                          ' Oggetto '||w_ogg.tr4_oggetto||
--                                          ' titr '||w_tipo_tributo
--                                          );
-- se non abbiamo trovato la denuncia proviamo a cercarla x l'altro tipo tributo
                  select w_ogg.documento_id
                        ,w_ogg.documento_multi_id
                        ,w_ogg.progr_oggetto
                        ,'O'
                        ,w_ogg.sezione
                        ,w_ogg.foglio
                        ,w_ogg.numero
                        ,w_ogg.subalterno
                        ,w_ogg.cod_via
                        ,w_ogg.indirizzo
                        ,w_ogg.num_civico
                        ,w_ogg.piano
                        ,w_ogg.scala
                        ,w_ogg.interno
                        ,w_ogg.zona
                        ,nvl(ogpr.categoria_catasto,w_categoria_catasto)
                        ,nvl(ogpr.classe_catasto,w_classe_catasto)
                        ,w_ogg.consistenza
                        ,w_ogg.superficie_catastale
                        ,f_valore(ogpr.valore, ogpr.tipo_oggetto, prtr.anno
                                , to_char(w_testata.data_realizzazione,'yyyy')
                                , ogpr.categoria_catasto, prtr.tipo_pratica
                                , ogpr.flag_valore_rivalutato) valore
                        ,ogpr.oggetto
                        ,ogpr.titolo
                        ,ogco.flag_esclusione
                        ,ogco.flag_ab_principale
                        ,ogco.cod_fiscale
                        ,ogco.oggetto_pratica
                        ,ogco.perc_possesso
                        ,ogpr.tipo_oggetto
                    into w_ogg_prec.documento_id
                        ,w_ogg_prec.documento_multi_id
                        ,w_ogg_prec.progr_oggetto
                        ,w_ogg_prec.tipo_operazione
                        ,w_ogg_prec.sezione
                        ,w_ogg_prec.foglio
                        ,w_ogg_prec.numero
                        ,w_ogg_prec.subalterno
                        ,w_ogg_prec.cod_via
                        ,w_ogg_prec.indirizzo
                        ,w_ogg_prec.num_civico
                        ,w_ogg_prec.piano
                        ,w_ogg_prec.scala
                        ,w_ogg_prec.interno
                        ,w_ogg_prec.zona
                        ,w_ogg_prec.categoria
                        ,w_ogg_prec.classe
                        ,w_ogg_prec.consistenza
                        ,w_ogg_prec.superficie_catastale
                        ,w_ogg_prec.rendita
                        ,w_ogg_prec.tr4_oggetto
                        ,w_titolo_prec
                        ,w_flag_esclusione_prec
                        ,w_flag_ab_princ_prec
                        ,w_cf_prec
                        ,w_ogpr_prec
                        ,w_perc_possesso_prec
                        ,w_tipo_oggetto_prec
                    from pratiche_tributo prtr
                        ,oggetti_pratica ogpr
                        ,oggetti_contribuente ogco
                   where ogco.oggetto_pratica = ogpr.oggetto_pratica
                     and ogpr.pratica = prtr.pratica
                     and ogco.cod_fiscale = w_sogg.codice_fiscale
                     and ogpr.oggetto = w_ogg.tr4_oggetto
                     and ogco.flag_possesso = 'S'
                     and prtr.tipo_tributo || '' = decode(w_tipo_tributo,'ICI','TASI','ICI')
                     and (nvl(prtr.documento_id,0) != a_documento_id
                         or nvl(prtr.documento_multi_id,0) != a_documento_multi_id)
-- dobbiamo escludere le denunce già caricate per questo docfa il tipo tributo diverso
                     and (ogco.anno || ogco.tipo_rapporto || 'S') =
                           (select max (   ogco_sub.anno
                                        || ogco_sub.tipo_rapporto
                                        || ogco_sub.flag_possesso
                                       )
                              from pratiche_tributo prtr_sub
                                  ,oggetti_pratica ogpr_sub
                                  ,oggetti_contribuente ogco_sub
                             where prtr_sub.tipo_tributo || '' = decode(w_tipo_tributo,'ICI','TASI','ICI')
                               and ( (prtr_sub.tipo_pratica || '' = 'D'
                                  and prtr_sub.data_notifica is null)
                                 or (prtr_sub.tipo_pratica || '' = 'A'
                                 and prtr_sub.data_notifica is not null
                                 and nvl (prtr_sub.stato_accertamento, 'D') = 'D'
                                 and nvl (prtr_sub.flag_denuncia, ' ') = 'S'
                                 and prtr_sub.anno <=
                                       to_char (w_testata.data_realizzazione
                                               ,'yyyy'
                                               )))
                               and prtr_sub.pratica = ogpr_sub.pratica
                               and ogco_sub.anno <=
                                     to_char (w_testata.data_realizzazione
                                             ,'yyyy'
                                             )
                               and ogco_sub.cod_fiscale = ogco.cod_fiscale
                               and ogco_sub.oggetto_pratica =
                                     ogpr_sub.oggetto_pratica
                               and ogpr_sub.oggetto = ogpr.oggetto
                               and ogco_sub.tipo_rapporto in ('C', 'D', 'E')
                               and nvl (ogco_sub.flag_possesso, 'N') =
                                     decode (decode(w_tipo_tributo,'ICI','TASI','ICI')
                                            ,'TASI', 'S'
                                            ,nvl (ogco_sub.flag_possesso, 'N')
                                            )
                               and (nvl(prtr_sub.documento_id,0) != a_documento_id
                                  or nvl(prtr_sub.documento_multi_id,0) != a_documento_multi_id)
                           );
                exception
                   when others then
                      w_perc_possesso_prec   := 0;
                      w_tipo_oggetto_prec    := null;
                      w_categoria_prec       := null;
                      w_classe_prec          := null;
                      w_valore_prec          := null;
                      w_titolo_prec          := null;
                      w_flag_esclusione_prec := null;
                      w_flag_ab_princ_prec   := null;
                      w_cf_prec              := null;
                      w_ogpr_prec            := null;
                      --
                      -- (VD - 15/03/2017): se non esiste una pratica "precedente",
                      -- si valorizzano categoria e classe catasto con i dati
                      -- presenti sul file DOCFA per evitare l'errore di
                      -- eccezione non trovata
                      --
                      w_ogg_prec.categoria   := w_categoria_catasto;
                      w_ogg_prec.classe      := w_classe_catasto;
                      --
                      -- (VD - 23/10/2017): se non esiste una pratica "precedente"
                      -- si valorizza la variabile tr4_oggetto per evitare
                      -- l'errore "cannot insert null into oggetti_pratica.oggetto"
                      --
                      w_ogg_prec.tr4_oggetto := w_ogg.tr4_oggetto;
                end;
              when others then
                w_perc_possesso_prec   := 0;
                w_tipo_oggetto_prec    := null;
                w_categoria_prec       := null;
                w_classe_prec          := null;
                w_valore_prec          := null;
                w_titolo_prec          := null;
                w_flag_esclusione_prec := null;
                w_flag_ab_princ_prec   := null;
                w_cf_prec              := null;
                w_ogpr_prec            := null;
                w_ogg_prec.categoria   := w_categoria_catasto;
                w_ogg_prec.classe      := w_classe_catasto;
                --
                -- (VD - 23/10/2017): se non esiste una pratica "precedente"
                -- si valorizza la variabile tr4_oggetto per evitare
                -- l'errore "cannot insert null into oggetti_pratica.oggetto"
                --
                w_ogg_prec.tr4_oggetto := w_ogg.tr4_oggetto;
            end;

            w_flag_possesso           := null;
            w_mesi_possesso           :=
              to_number (to_char (w_testata.data_realizzazione, 'mm'));
            if to_number (to_char (w_testata.data_realizzazione, 'dd')) <= 15 then
              w_mesi_possesso := w_mesi_possesso - 1;
            end if;
            if w_testata.data_realizzazione >
                 to_date (   '3006'
                          || to_char (w_testata.data_realizzazione, 'yyyy')
                         ,'ddmmyyyy'
                         ) then
              w_mesi_possesso_1sem := 6;
            else
              w_mesi_possesso_1sem      :=
                to_number (to_char (w_testata.data_realizzazione, 'mm'));
              if to_number (to_char (w_testata.data_realizzazione, 'dd')) <=
                   15 then
                w_mesi_possesso_1sem := w_mesi_possesso_1sem - 1;
              end if;
            end if;
--            w_mesi_possesso           := 12 - w_mesi_possesso;
--            w_mesi_possesso_1sem      := 6 - w_mesi_possesso_1sem;
            w_sogg_prec               := w_sogg;
            w_sogg_prec.perc_possesso := w_perc_possesso_prec;
            inserisce_pratica (w_tipo_tributo
                              ,w_testata.data_realizzazione
                              ,w_tipo_oggetto
                              ,w_sogg_prec
                              ,w_ogg_prec
                              ,w_testata
                              ,w_flag_possesso
                              ,w_mesi_possesso
                              ,w_mesi_possesso_1sem
                              ,w_titolo_prec
                              );
          end if;


          if w_ogg.tipo_operazione in ('C', 'V') then -- costituzione o variazione
            w_flag_possesso := 'S';
            w_mesi_possesso      :=
              13 - to_number (to_char (w_testata.data_realizzazione, 'mm'));
            if to_number (to_char (w_testata.data_realizzazione, 'dd')) > 15 then
              w_mesi_possesso := w_mesi_possesso - 1;
            end if;
            if w_testata.data_realizzazione >
                 to_date (   '3006'
                          || to_char (w_testata.data_realizzazione, 'yyyy')
                         ,'ddmmyyyy'
                         ) then
              w_mesi_possesso_1sem := 0;
            else
              w_mesi_possesso_1sem      :=
                7 - to_number (to_char (w_testata.data_realizzazione, 'mm'));
              if to_number (to_char (w_testata.data_realizzazione, 'dd')) > 15 then
                w_mesi_possesso_1sem := w_mesi_possesso_1sem - 1;
              end if;
            end if;



            -- inserimento denuncia
            inserisce_pratica (w_tipo_tributo
                              ,w_testata.data_realizzazione
                              ,w_tipo_oggetto
                              ,w_sogg
                              ,w_ogg
                              ,w_testata
                              ,w_flag_possesso
                              ,w_mesi_possesso
                              ,w_mesi_possesso_1sem
                              ,'A'
                              );
          end if;

        end loop; -- loop tipo tributo



      end loop; --loop soggetti
    end loop; --loop oggetti
  end if;
  delete wrk_docfa_testata
  where  documento_id = a_documento_id
  and    documento_multi_id = a_documento_multi_id
  ;
  --
  -- (VD - 13/01/2020): Archiviazione pratiche inserite
  -- (VD - 11/02/2020): Aggiunto test su indice array
  --
  if w_ind > 0 then
     for w_ind in t_pratica.first .. t_pratica.last
     loop
       if t_pratica(w_ind) is not null then
          archivia_denunce('','',t_pratica(w_ind));
       end if;
     end loop;
  end if;
exception
  when errore then
    rollback;
    raise_application_error (-20999, nvl (w_errore, 'vuoto'));
--  a_messaggio      :=
--       upper (a_tipo_tributo)
--    || ': '
--    || chr (10)
--    || chr (13)
--    ||
--    'Inserite '
--    || to_char (w_num_pratiche)
--    || ' pratiche '
--    || chr (13)
--    || 'Inseriti '
--    || to_char (w_num_nuovi_oggetti)
--    || ' nuovi oggetti'
--    || chr (13)
--    || 'Inseriti '
--    || to_char (w_num_nuovi_contribuenti)
--    || ' nuovi contribuenti'
--    || chr (13)
--    || 'Inseriti '
--    || to_char (w_num_nuovi_soggetti)
--    || ' nuovi soggetti'
--    || chr (13)
--    || 'Trattati '
--    || to_char (w_num_soggetti)
--    || ' Soggetti su '
--    || to_char (w_num_soggetti_xml)
--    || ' Presenti'
--    || chr (13)
--    || 'Trattate '
--    || to_char (w_num_nuovi_ogpr)
--    || ' Titolarità su '
--    || to_char (w_num_titolarita)
--    || ' Presenti'
--    || chr (13)
--    || 'Titolarità senza Acquisizione e Cessione: '
--    || to_char (w_num_no_acq_ces)
--    || chr (13)
--    || 'Oggetti Anomali inseriti: '
--    || to_char (w_num_oggetti_anomali);
  when others then
    rollback;
    a_messaggio := '';
    raise_application_error (-20999, 'Errore CONVALIDA_DOCFA '||sqlerrm);
end;
/* End Procedure: CONVALIDA_DOCFA */
/
