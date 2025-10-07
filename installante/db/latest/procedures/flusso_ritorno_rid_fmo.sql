--liquibase formatted sql 
--changeset abrandolini:20250326_152423_flusso_ritorno_rid_fmo stripComments:false runOnChange:true 
 
create or replace procedure FLUSSO_RITORNO_RID_FMO
/*************************************************************************
 NOME:        FLUSSO_RITORNO_RID_FMO
 DESCRIZIONE: Carica i dati presenti nel flusso di ritorno RID
              per Fiorano Modenese.
 NOTE:
 Rev.    Date         Author      Note
 000     21/08/2018   VD          Prima emissione.
*************************************************************************/
( a_documento_id     in      number
, a_utente           in      varchar2
, a_messaggio        in out  varchar2
) is
  w_documento_blob           blob;
  w_documento_clob           clob;
  dest_offset                number := 1;
  src_offset                 number := 1;
  amount                     integer := DBMS_LOB.lobmaxsize;
  blob_csid                  number  := DBMS_LOB.default_csid;
  lang_ctx                   integer := DBMS_LOB.default_lang_ctx;
  warning                    integer;
  w_stato                    number;
  w_nome_documento           documenti_caricati.nome_documento%type;
  w_dimensione_file          number;
  w_posizione                number;
  w_posizione_old            number;
  w_riga                     varchar2 (32767);
  w_progr_disposizione       number := 0;
  w_cod_fiscale              varchar2(16);
  w_ni                       number;
  w_data_pagamento           date;
  w_importo                  number;
  w_cognome_nome             varchar2(60);
  w_anno                     number;
  w_rata                     number;
  w_num_ruoli                number;
  w_sequenza                 number;
  w_fonte                    number;
  w_tipo_tributo             varchar2(5) := 'TARSU';
  w_conta_disp               number := 0;
  w_conta_anomalie           number := 0;
  w_messaggio                varchar2(2000);
  sql_errm                   varchar2(200);
  errore                     exception;
  w_errore                   varchar2(200);
BEGIN
  -- Estrazione BLOB
  begin
    select contenuto
         , stato
         , nome_documento
      into w_documento_blob
         , w_stato
         , w_nome_documento
      from documenti_caricati doca
     where doca.documento_id  = a_documento_id
    ;
  end;
  if w_stato = 1 then
    -- Verifica dimensione file caricato
    w_dimensione_file:= DBMS_LOB.GETLENGTH(w_documento_blob);
    if nvl(w_dimensione_file,0) = 0 then
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
        w_errore :=
          'Errore in trasformazione Blob in Clob  (' || sqlerrm || ')';
        raise errore;
    end;
    --
    w_fonte := to_number(f_inpa_valore('FONT_RID'));
    w_posizione_old     := 1;
    w_posizione         := 1;
    --
    while w_posizione < w_dimensione_file
    loop
      w_posizione     := instr (w_documento_clob, chr (10), w_posizione_old);
      w_riga          := substr (w_documento_clob, w_posizione_old, w_posizione-w_posizione_old+1);
      w_posizione_old := w_posizione + 1;
      -- Riga '10'
      if substr(w_riga, 2,2) = '10' then
         w_conta_disp         := w_conta_disp + 1;
         w_messaggio          := null;
         w_progr_disposizione := to_number(substr(w_riga,4,7));
         w_data_pagamento     := to_date(substr(w_riga,23,6),'ddmmyy');
         w_importo            := to_number(substr(w_riga,34,13)) / 100;
         w_cod_fiscale        := null;
         w_ni                 := to_number(null);
         if substr(w_riga,97,1) = 3 then
            w_cod_fiscale     := ltrim(rtrim(substr(w_riga,98,16)));
         elsif
            substr(w_riga,97,1) = 4 then
            w_ni              := to_number(ltrim(rtrim(substr(w_riga,98,16))));
         end if;
         if w_cod_fiscale is null then
            if w_ni is null then
               w_messaggio := 'Impossibile determinare il contribuente - progr.disp. '||w_progr_disposizione||
                              ' - Importo pagato '||w_importo;
            else
               begin
                 select cod_fiscale
                   into w_cod_fiscale
                   from contribuenti
                  where ni = w_ni
                      ;
               EXCEPTION
                 WHEN no_data_found THEN
                   w_messaggio := 'Contribuente non presente - ni '||w_ni||
                                  ' - Importo pagato '||w_importo;
                 WHEN others THEN
                   w_messaggio := 'Impossibile determinare il contribuente - ni '||w_ni||
                                  ' - Importo pagato '||w_importo;
               end;
            end if;
         else
            begin
              select ni
                into w_ni
                from contribuenti
               where cod_fiscale = w_cod_fiscale
                   ;
            EXCEPTION
              WHEN no_data_found THEN
                w_messaggio := 'Contribuente non presente - cod.fiscale '||w_cod_fiscale||
                                  ' - Importo pagato '||w_importo;
              WHEN others THEN
                w_messaggio := 'Impossibile determinare il contribuente - cod.fiscale '||w_cod_fiscale||
                               ' - Importo pagato '||w_importo;
            end;
         end if;
      end if;
      -- Riga '30' (solo per memorizzare denominazione contribuente)
      if substr(w_riga, 2,2) = '30' then
         if to_number(substr(w_riga,4,7)) <> w_progr_disposizione then
            w_messaggio := 'Sequenza righe errata - progr.disp. '||w_progr_disposizione;
         else
            w_cognome_nome := substr(w_riga,11,60);
         end if;
      end if;
      -- Riga '50'
      if substr(w_riga, 2,2) = '50' then
         if to_number(substr(w_riga,4,7)) <> w_progr_disposizione then
            w_messaggio := 'Sequenza righe errata - progr.disp. '||w_progr_disposizione;
         else
            w_anno := to_number(substr(w_riga,25,4));
            w_rata := 0;
            if upper(substr(w_riga,32,5)) = 'PRIMA' then
               w_rata := 1;
            end if;
            if upper(substr(w_riga,32,7)) = 'SECONDA' then
               w_rata := 2;
            end if;
         end if;
         --
         -- (VD - 07/09/2018): aggiunto controllo esistenza ruolo per il
         -- contribuente
         --
         if w_cod_fiscale is not null and
            w_anno is not null then
            begin
              select count(*)
                into w_num_ruoli
                from ruoli_contribuente ruco
                   , ruoli              ruol
               where ruco.cod_fiscale = w_cod_fiscale
                 and ruco.ruolo       = ruol.ruolo
                 and ruol.anno_ruolo  = w_anno;
            exception
              when others then
                w_num_ruoli := 0;
            end;
            --
            if w_num_ruoli = 0 then
               w_messaggio := 'Nessun ruolo per il contribuente - ni: '||w_ni||
                              ' - Importo pagato '||w_importo;
            end if;
         end if;
         -- la riga '50' e' l'ultima riga necessaria al completamento dei dati,
         -- quindi si procede al caricamento del versamento
         if w_messaggio is null then
            select nvl(max(vers.sequenza),0)+1
              into w_sequenza
              from versamenti vers
             where vers.cod_fiscale     = w_cod_fiscale
               and vers.anno            = w_anno
               and vers.tipo_tributo    = w_tipo_tributo
                 ;
            begin
              insert into versamenti
                   (cod_fiscale
                   ,anno
                   ,tipo_tributo
                   ,sequenza
                   ,descrizione
                   ,data_pagamento
                   ,importo_versato
                   ,fonte
                   ,utente
                   ,data_variazione
                   ,data_reg
                   ,rata
                   ,documento_id
                   )
             values(w_cod_fiscale
                   ,w_anno
                   ,w_tipo_tributo
                   ,w_sequenza
                   ,'VERSAMENTO IMPORTATO DA FLUSSO RID'
                   ,w_data_pagamento
                   ,w_importo
                   ,w_fonte
                   ,a_utente
                   ,trunc(sysdate)
                   ,trunc(sysdate)
                   ,w_rata
                   ,a_documento_id
                   )
                   ;
            exception
              when others then
                w_errore := 'Errore in inserimento versamento - Contribuente: '||
                            w_cod_fiscale||' - '||sqlerrm;
                raise errore;
            end;
         else
            -- inserimento anomalia caricamento
            w_conta_anomalie := w_conta_anomalie + 1;
            begin
              insert into anomalie_caricamento
                          ( documento_id
                          , sequenza
                          , cognome
                          , cod_fiscale
                          , descrizione
                          , note
                          )
                   values ( a_documento_id
                          , w_conta_anomalie
                          , substr(w_cognome_nome,1,60)
                          , w_cod_fiscale
                          , substr(w_messaggio,1,100)
                          , substr(w_riga,1,2000)
                          );
            exception
              when others then
                w_errore := 'Errore in inserimento anomalie_caricamento '
                         || ' (' || sqlerrm || ')';
                raise errore;
            end;
         end if;
      end if;
    END LOOP;
  end if;
  --
   a_messaggio := w_messaggio;
   -- Aggiornamento Stato
   begin
      update documenti_caricati
         set stato = 2
           , data_variazione = sysdate
           , utente = a_utente
           , note = 'Disposizioni trattate: '||to_char(w_conta_disp)||
                    ' - Disposizioni scartate: '||to_char(w_conta_anomalie)
       where documento_id = a_documento_id
           ;
   EXCEPTION
      WHEN others THEN
         sql_errm  := substr(SQLERRM,1,100);
         w_errore := 'Errore in Aggiornamneto Stato del documento '||
                                    ' ('||sql_errm||')';
   end;
   a_messaggio := 'Disposizioni trattate: '||to_char(w_conta_disp)||chr(13)||
                  'Disposizioni scartate: '||to_char(w_conta_anomalie);
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,w_errore||' ('||SQLERRM||')');
END;
/* End Procedure: FLUSSO_RITORNO_RID_FMO */
/

