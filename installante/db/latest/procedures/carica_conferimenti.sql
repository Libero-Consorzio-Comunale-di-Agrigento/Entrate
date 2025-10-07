--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_conferimenti stripComments:false runOnChange:true 
 
create or replace procedure CARICA_CONFERIMENTI
/*************************************************************************
 NOME:        CARICA_CONFERIMENTI
 DESCRIZIONE: Caricamento dati conferimenti da file (S.Donato Milanese)
 NOTE:
 Rev.    Date         Author      Note
 002     12/09/2017   VD          Corretto messaggio di fine elaborazione.
 001     02/11/2016               Prima emissione.
*************************************************************************/
( a_documento_id     in      number
, a_utente           in      varchar2
, a_messaggio        in out  varchar2
)
is
-- w_commenti abilita le dbms_outpt, può avere i seguenti valori:
--  0  =   Nessun Commento
--  1  =   Commenti principali Ablitati
  w_commenti              number := 0;
  w_documento_blob        blob;
  w_documento_clob        clob;
  dest_offset             number := 1;
  src_offset              number := 1;
  amount                  integer := DBMS_LOB.lobmaxsize;
  blob_csid               number  := DBMS_LOB.default_csid;
  lang_ctx                integer := DBMS_LOB.default_lang_ctx;
  warning                 integer;
  w_stato                 number;
  w_nome_documento        documenti_caricati.nome_documento%type;
  w_dimensione_file       number;
  w_posizione             number;
  w_posizione_old         number;
  w_riga                  varchar2 (32767);
  w_campo                 varchar2 (32767);
  w_separatore            varchar2(1) := ';';
  w_num_separatori        number;
  w_lunghezza_riga        number;
  w_inizio                number := 0;
  w_fine                  number;
  w_occorrenza            number;
  w_righe_caricate        number := 0;
  w_conta_anomalie        number := 0;
  w_cognome               soggetti.cognome%type;
  w_nome                  soggetti.nome%type;
  rec_conf                conferimenti%rowtype;
  w_errore                varchar(2000) := NULL;
  errore                  exception;
  sql_errm                varchar2(100);
begin
   if w_commenti > 0 then
      DBMS_OUTPUT.Put_Line('---- Inizio ----');
   end if;
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
     w_posizione_old     := 1;
     w_posizione         := 1;
     --
     while w_posizione < w_dimensione_file
     loop
       w_posizione     := instr (w_documento_clob, chr (10), w_posizione_old);
       w_riga          := substr (w_documento_clob, w_posizione_old, w_posizione-w_posizione_old+1);
       w_posizione_old := w_posizione + 1;
       -- Determinazione numero di separatori presenti nella riga
       w_num_separatori := length(w_riga) - length(replace(w_riga,w_separatore,''));
       w_lunghezza_riga := length(w_riga);
       w_inizio     := 1;
       w_occorrenza := 1;
       rec_conf     := null;
       --
       begin
         while w_occorrenza <= w_num_separatori
         loop
           w_fine := instr(w_riga,w_separatore,w_inizio,1);
           w_campo := rtrim(substr(w_riga,w_inizio,w_fine - w_inizio));
           if w_occorrenza = 1 then
              rec_conf.cod_fiscale := w_campo;
           elsif
              w_occorrenza = 2 then
              rec_conf.anno := to_number(w_campo);
           elsif
              w_occorrenza = 3 then
              rec_conf.sacchi := to_number(w_campo);
           end if;
           w_occorrenza := w_occorrenza + 1;
           w_inizio := instr(w_riga,w_separatore,w_inizio,1) + 1;
         end loop;
       exception
          when others then
            w_errore := substr('Riga : '||w_riga||' - '||sqlerrm,1,2000);
            raise errore;
       end;
       -- Controllo esistenza contribuente
       begin
         select sogg.cognome
              , sogg.nome
              , null
           into w_cognome
              , w_nome
              , w_errore
           from contribuenti cont
              , soggetti     sogg
          where cont.ni          = sogg.ni
            and cont.cod_fiscale = rec_conf.cod_fiscale;
       exception
         when no_data_found then
           w_errore := 'Contribuente non presente';
           w_conta_anomalie := w_conta_anomalie + 1;
           -- inserimento anomalia caricamento - contribuente non esistente
           begin
             insert into anomalie_caricamento
                         ( documento_id
                         , sequenza
                         , cod_fiscale
                         , descrizione
                         , note
                         )
                  values ( a_documento_id
                         , w_conta_anomalie
                         , rec_conf.cod_fiscale
                         , substr(w_errore,1,100)
                         , substr(w_riga,1,2000)
                         );
           exception
             when others then
               w_errore := 'Errore in inserimento anomalie_caricamento (contribuente assente) '
                        || ' (' || sqlerrm || ')';
               raise errore;
           end;
       end;
       if w_errore is null then
          if rec_conf.cod_fiscale is not null
          and rec_conf.anno        is not null
          and rec_conf.sacchi      is not null then
             --
             -- Controllo esistenza record
             --
             begin
               select 'Dati gia'' inseriti'
                 into w_errore
                 from conferimenti
                where cod_fiscale = rec_conf.cod_fiscale
                  and anno        = rec_conf.anno;
             exception
               when no_data_found then
                 w_errore := null;
               when too_many_rows then
                 w_errore := 'Dati gia'' inseriti';
             end;
             if w_errore is null then
                rec_conf.utente := a_utente;
                rec_conf.note   := 'Caricamento da file '||w_nome_documento;
                begin
                   insert into conferimenti
                   values rec_conf;
                exception
                  when others then
                    w_errore := substr('Ins. CONFERIMENTI (Contribuente: '
                             ||rec_conf.cod_fiscale||', Anno: '||rec_conf.anno
                             ||') - '
                             || sqlerrm,1,2000);
                    raise errore;
                end;
                w_righe_caricate := w_righe_caricate + 1;
             else
                -- inserimento anomalia caricamento - dati gia' presenti
                w_conta_anomalie := w_conta_anomalie + 1;
                begin
                  insert into anomalie_caricamento
                              ( documento_id
                              , sequenza
                              , cognome
                              , nome
                              , cod_fiscale
                              , descrizione
                              , note
                              )
                       values ( a_documento_id
                              , w_conta_anomalie
                              , w_cognome
                              , w_nome
                              , rec_conf.cod_fiscale
                              , substr(w_errore,1,100)
                              , substr(w_riga,1,2000)
                              );
                exception
                  when others then
                    w_errore := 'Errore in inserimento anomalie_caricamento (dati gia'' presenti) '
                             || ' (' || sqlerrm || ')';
                    raise errore;
                end;
             end if;
          end if;
       end if;
     end loop;
     -- Aggiornamento Stato
     begin
        update documenti_caricati
           set stato = 2
             , data_variazione = sysdate
             , utente = a_utente
             , note = 'Conferimenti: righe caricate '|| to_char(w_righe_caricate) ||', righe scartate: '||to_char(w_conta_anomalie)
         where documento_id = a_documento_id
             ;
     EXCEPTION
        WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           w_errore := 'Errore in Aggiornamento Stato del documento '||
                                      ' ('||sql_errm||')';
     end;
     a_messaggio := 'Caricate '|| to_char(w_righe_caricate) ||' righe di conferimenti.';
   end if;
EXCEPTION
   WHEN ERRORE THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,nvl(w_errore,'vuoto'));
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' - '||substr(SQLERRM,1,100));
end;
/* End Procedure: CARICA_CONFERIMENTI */
/

