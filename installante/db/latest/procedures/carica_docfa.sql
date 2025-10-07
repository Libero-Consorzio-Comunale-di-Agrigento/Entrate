--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_docfa stripComments:false runOnChange:true 
 
create or replace procedure CARICA_DOCFA
( a_documento_id   in     number
 ,a_utente         in     varchar2
 ,a_sezione_unica  in     varchar2
 ,a_fonte          in     number
 ,a_messaggio      in out varchar2
)
is
/***************************************************************************
27/01/2015 Betta T. Tolta to_number da num_registrazione tecnico
***************************************************************************/
  w_documento_blob           blob;
  w_documento_clob           clob;
  w_documento_blob2          blob;
  w_documento_clob2          clob;
  w_documento_multi_id       documenti_caricati_multi.documento_multi_id%type;
  w_nome_doc                 documenti_caricati_multi.nome_documento%type;
  dest_offset                number := 1;
  src_offset                 number := 1;
  amount                     integer := DBMS_LOB.lobmaxsize;
  blob_csid                  number := DBMS_LOB.default_csid;
  lang_ctx                   integer := DBMS_LOB.default_lang_ctx;
  warning                    integer;
  dest_offset2               number := 1;
  src_offset2                number := 1;
  amount2                    integer := DBMS_LOB.lobmaxsize;
  blob_csid2                 number := DBMS_LOB.default_csid;
  lang_ctx2                  integer := DBMS_LOB.default_lang_ctx;
  warning2                   integer;
  w_number_temp              number;
  w_dimensione_file          number;
  w_posizione                number;
  w_posizione_old            number;
  w_dimensione_file2         number;
  w_posizione2               number;
  w_posizione_old2           number;
  w_riga                     varchar2 (32767);
  w_riga2                    varchar2 (32767);
  w_nome_documento           varchar2 (255);
  w_nome_documento_old       varchar2 (255);
  w_tipo_record              varchar2 (1);
  w_errore                   varchar (2000) := null;
  w_sql_errm                 varchar (2000) := null;
  errore                     exception;
  w_conta_costituite         number;
  w_fine_loop                number;
  w_controllo                number;
  w_messaggio                varchar2 (32767) := null;
  w_versione                 CHAR(1);
  w_idx_indirizzo            NUMBER;
  --  type sogg_rec is record (progressivo_int   number (3)
  --                          ,denominazione     varchar2 (100)
  --                          ,comune_nascita    varchar2 (25)
  --                          ,provincia         varchar2 (2)
  --                          ,data_nascita      varchar2 (8) -- GGMMYYYY
  --                          ,sesso             varchar2 (1)
  --                          ,codice_fiscale    varchar2 (26)
  --                          ,soggetto          soggetti.ni%type
  --                          ,cognome           soggetti.cognome%type
  --                          ,nome              soggetti.nome%type
  --                          ,tipo              soggetti.tipo%type);
  type sogg_tab is table of wrk_docfa_soggetti%rowtype
                     index by binary_integer;
  w_sogg                     sogg_tab;
  i_sogg                     binary_integer;
  --  type ogg_rec is record (documento_id      number
  --                         ,documento_multi_id number
  --                         ,progressivo_ui    number (3)
  --                         ,tipo_operazione   varchar2 (1) -- C-costituita V-variata S-soppressa
  --                         ,sezione           varchar2 (3)
  --                         ,foglio            varchar2 (4)
  --                         ,numero            varchar2 (5)
  ----                         ,denominatore      varchar2 (4)
  --                         ,subalterno        varchar2 (4)
  --                         ,codice_strada     varchar2 (5)
  --                         ,indirizzo         varchar2 (44)
  --                         ,numero_civico     varchar2 (6)
  --                         ,piano             varchar2 (4)
  --                         ,scala             varchar2 (2)
  --                         ,interno           varchar2 (3)
  --                         ,zona_censuaria    varchar2 (3)
  --                         ,categoria         varchar2 (3)
  --                         ,classe            varchar2 (2)
  --                         ,consistenza       varchar2 (6)
  --                         ,sup_catastale     varchar2 (5)
  --                         ,rendita           number (10, 2)
  --                         ,oggetto           oggetti.oggetto%type);
  type ogg_tab is table of wrk_docfa_oggetti%rowtype
                    index by binary_integer;
  w_ogg                      ogg_tab;
  i_ogg                      binary_integer;
  w_cognome_tec              varchar2 (24);
  w_nome_tec                 varchar2 (20);
  w_cod_fiscale_tec          varchar2 (16);
  w_albo_tec                 number (2);
  w_num_iscr_tec             varchar2 (5);
  w_prov_iscr_tec            varchar2 (2);
  w_cognome_dic              varchar2 (24);
  w_nome_dic                 varchar2 (20);
  w_comune_dic               varchar2 (25);
  w_provincia_dic            varchar2 (2);
  w_indirizzo_dic            varchar2 (35);
  w_civico_dic               varchar2 (5);
  w_cap_dic                  varchar2 (5);
  w_unita_dest_ord           number (3);
  w_unita_dest_spec          number (3);
  w_unita_non_censite        number (3);
  w_unita_soppresse          number (3);
  w_unita_variate            number (3);
  w_unita_costituite         number (3);
  w_causale                  varchar2 (3);
  w_note1                    varchar2 (35);
  w_note2                    varchar2 (35);
  w_note3                    varchar2 (35);
  w_note4                    varchar2 (42);
  w_note5                    varchar2 (380);
  w_data_realizzazione       date;
  -- campi x inserimento oggetti
  w_estremi_catasto          oggetti.estremi_catasto%type;
  w_num_civ                  oggetti.num_civ%type;
  w_suffisso                 oggetti.suffisso%type;
  w_dati_oggetto             varchar2 (2000);
  w_civico                   varchar2 (6);
  w_num_oggetti_anomali      number := 0;
  w_num_nuovi_oggetti        number := 0;
  -- campi x inserimento contribuenti
  w_anomalia_cont            varchar2 (1); --serve??
  w_ni                       number;
  w_cod_fiscale              varchar2 (16);
  w_cancella_contribuente    varchar2 (1); --serve??
  w_cancella_soggetto        varchar2 (1); --serve??
  w_cod_com_nas              ad4_comuni.comune%type;
  w_cod_pro_nas              ad4_comuni.provincia_stato%type;
  w_num_nuovi_soggetti       number;
  w_num_nuovi_contribuenti   number;
begin
   -- Cambio stato in caricamento in corso per gestione Web
   update documenti_caricati
           set stato = 15
             , data_variazione = sysdate
             , utente = a_utente
         where documento_id = a_documento_id
             ;
   commit;
  a_messaggio := '';
  -- Estrazione BLOB
  begin
    select contenuto
      into w_documento_blob
      from documenti_caricati doca
     where doca.documento_id = a_documento_id;
  end;
  -- Verifica dimensione file caricato
  w_number_temp        := DBMS_LOB.getlength (w_documento_blob);
  if nvl (w_number_temp, 0) = 0 then
    w_errore := 'Attenzione File caricato Vuoto - Verificare Client Oracle';
    raise errore;
  end if;
  -- Trasformazione in CLOB
  begin
    DBMS_LOB.createtemporary (lob_loc =>   w_documento_clob
                             ,cache =>     true
                             ,dur =>       DBMS_LOB.session
                             );
    DBMS_LOB.converttoclob (w_documento_clob
                           ,w_documento_blob
                           ,amount
                           ,dest_offset
                           ,src_offset
                           ,blob_csid
                           ,lang_ctx
                           ,warning
                           );
  exception
    when others then
      w_errore      :=
        'Errore in trasformazione Blob in Clob  (' || sqlerrm || ')';
      raise errore;
  end;
  w_posizione_old      := 1;
  w_posizione          := 1;
  w_number_temp        := length (w_documento_clob);
  w_nome_documento_old := '!';
  w_documento_multi_id := -1;
  while w_posizione < w_number_temp loop
    w_posizione     := instr (w_documento_clob, chr (10), w_posizione_old);
    w_riga          := substr (w_documento_clob, w_posizione_old, w_posizione-w_posizione_old+1);
    w_posizione_old := w_posizione + 1;
    w_nome_documento      :=
      substr (w_riga
             ,instr (w_riga, '|', 1, 3) + 1
             ,instr (w_riga, '|', 1, 4) - instr (w_riga, '|', 1, 3) - 1
             );
    if w_nome_documento = w_nome_documento_old then
      null;
    else
      w_sogg.delete;
      w_ogg.delete;
      begin
        select contenuto, documento_multi_id, nome_documento
          into w_documento_blob2, w_documento_multi_id, w_nome_doc
          from documenti_caricati_multi
         where documento_id = a_documento_id
           and nome_documento = w_nome_documento || '.DAT';
      exception
        when others then w_errore := substr('Errore in lettura file DOCFA nome: '||w_nome_documento|| sqlerrm,1,2000);
                         a_messaggio := w_errore;
                         raise errore;
      end;
      -- Verifica dimensione file caricato
      w_dimensione_file2   := DBMS_LOB.getlength (w_documento_blob2);
      if nvl (w_dimensione_file2, 0) = 0 then
        w_errore      :=
          'Attenzione File caricato Vuoto - Verificare Client Oracle';
        raise errore;
      end if;
      dest_offset2         := 1;
      src_offset2          := 1;
      begin
        DBMS_LOB.createtemporary (lob_loc =>   w_documento_clob2
                                 ,cache =>     true
                                 ,dur =>       DBMS_LOB.session
                                 );
        DBMS_LOB.converttoclob (w_documento_clob2
                               ,w_documento_blob2
                               ,amount2
                               ,dest_offset2
                               ,src_offset2
                               ,blob_csid2
                               ,lang_ctx2
                               ,warning2
                               );
      exception
        when others then
          w_errore      :=
               'Errore in trasformazione Blob in Clob file '
            || w_nome_documento
            || ' ('
            || sqlerrm
            || ')';
          raise errore;
      end;
      w_posizione_old2     := 1;
      w_posizione2         := 1;
      w_dimensione_file2   := length (w_documento_clob2);
      i_sogg               := 0;
      i_ogg                := 0;
      w_conta_costituite   := 0;
      w_unita_dest_ord     := null;
      w_unita_dest_spec    := null;
      w_unita_non_censite  := null;
      w_unita_soppresse    := null;
      w_unita_variate      := null;
      w_unita_costituite   := null;
      w_causale            := null;
      w_note1              := null;
      w_note2              := null;
      w_note3              := null;
      w_note4              := null;
      w_note5              := null;
      w_cognome_dic        := null;
      w_nome_dic           := null;
      w_comune_dic         := null;
      w_provincia_dic      := null;
      w_indirizzo_dic      := null;
      w_civico_dic         := null;
      w_cap_dic            := null;
      w_cognome_tec        := null;
      w_nome_tec           := null;
      w_cod_fiscale_tec    := null;
      w_albo_tec           := null;
      w_num_iscr_tec       := null;
      w_prov_iscr_tec      := null;
      while w_posizione2 < w_dimensione_file2 loop
        w_posizione2     := instr (w_documento_clob2, chr (10), w_posizione_old2);
        w_riga2          :=
          substr (w_documento_clob2, w_posizione_old2, w_posizione2-w_posizione_old2+1);
        w_posizione_old2 := w_posizione2 + 1;
        w_tipo_record    := substr (w_riga2, 17, 1);
        if w_tipo_record = 'A' then -- dati del dichiarante
          w_cognome_dic     := rtrim (substr (w_riga2, 18, 24));
          w_nome_dic        := rtrim (substr (w_riga2, 42, 20));
          w_comune_dic      := rtrim (substr (w_riga2, 62, 24));
          w_provincia_dic   := rtrim (substr (w_riga2, 87, 2));
          w_indirizzo_dic   := rtrim (substr (w_riga2, 89, 35));
          w_civico_dic      := ltrim (rtrim (substr (w_riga2, 124, 5)), '0');
          w_cap_dic         := rtrim (substr (w_riga2, 129, 5));
          w_cognome_tec     := rtrim (substr (w_riga2, 134, 24));
          w_nome_tec        := rtrim (substr (w_riga2, 158, 20));
          w_cod_fiscale_tec := rtrim (substr (w_riga2, 178, 16));
          w_albo_tec        := to_number (rtrim (substr (w_riga2, 194, 2)));
          w_num_iscr_tec    := rtrim (substr (w_riga2, 196, 5));
          w_prov_iscr_tec   := rtrim (substr (w_riga2, 201, 2));
        elsif w_tipo_record = '1' then -- dati generali
          w_unita_dest_ord    := to_number (rtrim (substr (w_riga2, 77, 3)));
          w_unita_dest_spec   := to_number (rtrim (substr (w_riga2, 80, 3)));
          w_unita_non_censite := to_number (rtrim (substr (w_riga2, 83, 3)));
          w_unita_soppresse   := to_number (rtrim (substr (w_riga2, 86, 3)));
          w_unita_variate     := to_number (rtrim (substr (w_riga2, 89, 3)));
          w_unita_costituite  := to_number (rtrim (substr (w_riga2, 92, 3)));
          w_causale           := rtrim (substr (w_riga2, 26, 3));
          w_note1             := rtrim (substr (w_riga2, 128, 35));
          w_note2             := rtrim (substr (w_riga2, 163, 35));
          w_note3             := rtrim (substr (w_riga2, 198, 35));
          w_note4             := rtrim (substr (w_riga2, 233, 42));
          begin
            w_data_realizzazione      :=
            to_date (lpad (nvl (ltrim (substr (w_riga2, 18, 8), '0')
                               ,ltrim (substr (w_riga2, 37, 8), '0')
                               )
                          ,8
                          ,'0'
                          )
                    ,'ddmmyyyy'
                    );
          exception
            when others -- non è una data
            then w_data_realizzazione := null;
          end;
        elsif w_tipo_record = '2' then -- intestati
          i_sogg                             := i_sogg + 1;
          w_sogg (i_sogg).documento_id       := a_documento_id;
          w_sogg (i_sogg).documento_multi_id := w_documento_multi_id;
          w_sogg (i_sogg).progr_soggetto      :=
            to_number (substr (w_riga2, 9, 3));
          w_sogg (i_sogg).denominazione      :=
            rtrim (substr (w_riga2, 25, 100));
          w_sogg (i_sogg).comune_nascita      :=
            rtrim (substr (w_riga2, 125, 25));
          w_sogg (i_sogg).provincia_nascita      :=
            rtrim (substr (w_riga2, 150, 2));
          begin
            w_sogg (i_sogg).data_nascita       :=
              to_date (substr (w_riga2, 152, 8), 'ddmmyyyy'); -- GGMMYYYY
          exception
            when others then -- non è una data
                        w_sogg (i_sogg).data_nascita       := null;
          end;
          w_sogg (i_sogg).sesso              :=
            rtrim (substr (w_riga2, 160, 1));
          w_sogg (i_sogg).codice_fiscale      :=
            rtrim (substr (w_riga2, 161, 16));
          if length (w_sogg (i_sogg).codice_fiscale) = 11 then
            w_sogg (i_sogg).cognome := null;
            w_sogg (i_sogg).nome    := null;
            w_sogg (i_sogg).tipo    := 1; -- persona giuridica
          else
            w_sogg (i_sogg).cognome      :=
              rtrim (substr (w_sogg (i_sogg).denominazione, 1, 50));
            w_sogg (i_sogg).nome      :=
              rtrim (substr (w_sogg (i_sogg).denominazione, 51,36));
            w_sogg (i_sogg).denominazione      :=
              w_sogg (i_sogg).cognome || '/' || w_sogg (i_sogg).nome;
            w_sogg (i_sogg).tipo := 0; -- persona fisica
          end if;
          w_sogg (i_sogg).flag_caricamento   := 'D'; -- Docfa
          w_sogg (i_sogg).regime             :=
            rtrim (substr (w_riga2, 179, 1));
          w_sogg (i_sogg).progressivo_int_rif      :=
            to_number (substr (w_riga2, 180, 2));
          w_sogg (i_sogg).spec_diritto       :=
            rtrim (substr (w_riga2, 183, 50));
          begin
            w_sogg (i_sogg).perc_possesso      :=
                to_number (substr (w_riga2, 233, 9))
              / to_number (substr (w_riga2, 242, 6))
              * 100;
          exception
            when others
            then w_sogg (i_sogg).perc_possesso      := null;
          end;
          w_sogg (i_sogg).titolo             :=
            ltrim (rtrim (substr (w_riga2, 250, 3)), '0');
        elsif w_tipo_record = '3' then -- unita immobiliari
          if substr(w_riga2,18,1) != 'A' then -- bene comune non censibile, non lo carichiamo
            -- Recupero della versione
            w_versione                         := substr (w_riga2, 46, 1);
            CASE substr (w_riga2, 46, 1)
                 WHEN '*' THEN w_idx_indirizzo := 52; -- VERS.3
                 WHEN '#' THEN w_idx_indirizzo := 54; -- VERS.4
                 WHEN '/' THEN w_idx_indirizzo := 58; -- VERS.4.00.2
                 ELSE
                            BEGIN
                                IF (NVL(RTRIM(TRANSLATE(LOWER(substr (w_riga2, 46, 1)), 'abcdefghijklmnopqrstuvwxyz', ' ')),
                         'TRUE') = 'TRUE') THEN
                                     w_idx_indirizzo := 46; -- Indirizzo fuori standard. Non viene indicata la versione
                                 ELSE
                                    w_idx_indirizzo := 52; -- Possibile nuova versione non cancora gestita
                           END IF;
                              END;
            END CASE;
            i_ogg                              := i_ogg + 1;
            w_ogg (i_ogg).documento_id         := a_documento_id;
            w_ogg (i_ogg).documento_multi_id   := w_documento_multi_id;
            w_ogg (i_ogg).progr_oggetto        :=
              to_number (substr (w_riga2, 9, 3));
            w_ogg (i_ogg).tipo_operazione      := substr (w_riga2, 25, 1); -- C-costituita V-variata S-soppressa
            if w_ogg (i_ogg).tipo_operazione = 'C' then
              w_conta_costituite := w_conta_costituite + 1;
            end if;
            if NVL (a_sezione_unica, 'N') = 'S' then
              w_ogg (i_ogg).sezione              := null;
            else
              w_ogg (i_ogg).sezione              :=
                ltrim (rtrim (substr (w_riga2, 26, 3)), '0');
            end if;
            w_ogg (i_ogg).foglio               :=
              ltrim (rtrim (substr (w_riga2, 29, 4)), '0');
            w_ogg (i_ogg).numero               :=
              ltrim (rtrim (substr (w_riga2, 33, 5)), '0');
            --          w_ogg (i_ogg).denominatore    := rtrim (substr (w_riga2, 38, 4));
            w_ogg (i_ogg).subalterno           :=
              ltrim (rtrim (substr (w_riga2, 42, 4)), '0');
            w_ogg (i_ogg).cod_via              := null; --rtrim(substr(w_riga2, 47, 5));
            dbms_output.put_line('Indirizzo: [' || rtrim(substr(w_riga2, w_idx_indirizzo, 95 - w_idx_indirizzo + 1) || ']'));
            w_ogg (i_ogg).indirizzo            :=
               rtrim(substr (w_riga2, w_idx_indirizzo, 95 - w_idx_indirizzo + 1));
            w_ogg (i_ogg).num_civico           :=
              ltrim (rtrim (substr (w_riga2, 97, 5)), '0'); -- perdiamo chr a sx
            w_ogg (i_ogg).piano                :=
              rtrim (substr (w_riga2, 114, 4));
            w_ogg (i_ogg).scala                :=
              rtrim (substr (w_riga2, 126, 2));
            w_ogg (i_ogg).interno              :=
              rtrim (substr (w_riga2, 128, 3));
            w_ogg (i_ogg).zona                 :=
              rtrim (substr (w_riga2, 160, 3));
            w_ogg (i_ogg).categoria            :=
              rtrim (substr (w_riga2, 163, 3));
            if w_ogg (i_ogg).categoria like ' %' then
              w_ogg (i_ogg).categoria := null;
            end if;
            w_ogg (i_ogg).classe               :=
              rtrim (substr (w_riga2, 166, 2));
            w_ogg (i_ogg).consistenza          :=
              rtrim (substr (w_riga2, 168, 6));
            w_ogg (i_ogg).superficie_catastale      :=
              to_number (substr (w_riga2, 175, 5));
            w_ogg (i_ogg).rendita              :=
              to_number (substr (w_riga2, 180, 10)) / 100;
            w_ogg (i_ogg).tr4_oggetto          := null;
          end if;
        elsif w_tipo_record = '9' then -- annotazioni
          if to_number (substr (w_riga2, 12, 5)) = 0 then
            w_note5 := rtrim (substr (w_riga2, 18, 68));
          else
            w_note5 := w_note5 || rtrim (substr (w_riga2, 18, 312));
          end if;
        end if;
      end loop;
      DBMS_OUTPUT.put_line (   'PRIMA DELLE INSERT oggetti'
                            || i_ogg
                            || ' soggetti '
                            || i_sogg
                            || 'x'
                           );
 --      se il documento esiste già lo cancelliamo, (non dovrebbe succedere)
--       la cancellazione della testata cancella anche i dettagli
      delete wrk_docfa_testata
       where documento_id = a_documento_id
         and documento_multi_id = w_documento_multi_id;
      insert
        into wrk_docfa_testata (documento_id
                               ,documento_multi_id
                               ,unita_dest_ord
                               ,unita_dest_spec
                               ,unita_non_censite
                               ,unita_soppresse
                               ,unita_variate
                               ,unita_costituite
                               ,causale
                               ,note1
                               ,note2
                               ,note3
                               ,note4
                               ,note5
                               ,cognome_dic
                               ,nome_dic
                               ,comune_dic
                               ,provincia_dic
                               ,indirizzo_dic
                               ,civico_dic
                               ,cap_dic
                               ,cognome_tec
                               ,nome_tec
                               ,cod_fiscale_tec
                               ,albo_tec
                               ,num_iscrizione_tec
                               ,prov_iscrizione_tec
                               ,data_realizzazione
                               ,fonte
                               )
      values (a_documento_id
             ,w_documento_multi_id
             ,w_unita_dest_ord
             ,w_unita_dest_spec
             ,w_unita_non_censite
             ,w_unita_soppresse
             ,w_unita_variate
             ,w_unita_costituite
             ,w_causale
             ,w_note1
             ,w_note2
             ,w_note3
             ,w_note4
             ,w_note5
             ,w_cognome_dic
             ,w_nome_dic
             ,w_comune_dic
             ,w_provincia_dic
             ,w_indirizzo_dic
             ,w_civico_dic
             ,w_cap_dic
             ,w_cognome_tec
             ,w_nome_tec
             ,w_cod_fiscale_tec
             ,w_albo_tec
             ,w_num_iscr_tec
             ,w_prov_iscr_tec
             ,w_data_realizzazione
             ,a_fonte
             );
-- se non abbiamo trovato oggetti w_ogg.first e .last sono nulli. In questo caso non dobbiamo entrare nel loop
-- quindi il -1 nel secondo  nvl e' voluto
-- mettiamo a capo dopo i due punti perche power designer altrimenti si mangia la riga...
      for i_ogg in nvl(w_ogg.first,0) ..
          nvl(w_ogg.last,-1) loop
        insert into wrk_docfa_oggetti
             values w_ogg (i_ogg);
        if w_sogg.count > 0 then
          for i_sogg in w_sogg.first .. w_sogg.last loop
            w_sogg (i_sogg).progr_oggetto := w_ogg (i_ogg).progr_oggetto;
            insert into wrk_docfa_soggetti
                 values w_sogg (i_sogg);
          end loop;
        end if;
      end loop;
      DBMS_OUTPUT.put_line (   'DOPO LE INSERT oggetti'
                            || i_ogg
                            || ' soggetti '
                            || i_sogg
                            || 'x'
                           );
      if (i_sogg > 0 -- abbiamo i soggetti
      and i_ogg > 0 -- abbiamo gli oggetti
      and w_conta_costituite = i_ogg -- e gli oggetti sono tutte costituzioni
      and w_data_realizzazione is not null) then  -- e abbiamo una data
        DBMS_OUTPUT.put_line (   'Eseguirebbe convalida x documento '
                              || w_nome_doc
                              || 'x'
                             );
        convalida_docfa(a_documento_id,w_documento_multi_id,a_utente,w_messaggio);
        w_messaggio := nvl(w_messaggio, ' ') || w_messaggio;
      end if;
      w_nome_documento_old := w_nome_documento;
    end if;
  end loop;
  if w_documento_multi_id = -1 then
    begin
      update documenti_caricati
         set stato = 2
           , data_variazione = sysdate
           , utente = a_utente
           , note = 'Nessun documento DOCFA da caricare.'
       where documento_id = a_documento_id
     ;
    end;
    a_messaggio :=  'Nessun DOCFA da caricare';
  else
    begin
      update documenti_caricati
         set stato = 2
           , data_variazione = sysdate
           , utente = a_utente
           , note = 'Caricate '|| to_char(w_documento_multi_id) ||' testate di documenti DOCFA.'
       where documento_id = a_documento_id
     ;
    end;
    a_messaggio :=  rtrim(ltrim(w_messaggio));
  end if;
exception
  when errore then
    rollback;
    raise_application_error (-20999, nvl (w_errore, 'vuoto'));
--  when others then
--    rollback;
--    raise;
--    raise_application_error(-20999, substr(sqlerrm, 1, 200));
end;
/* End Procedure: CARICA_DOCFA */
/

