--liquibase formatted sql 
--changeset abrandolini:20250326_152429_esporta_standard stripComments:false runOnChange:true 
 
create or replace package ESPORTA_STANDARD is
/******************************************************************************
 NOME:        ESPORTA_STANDARD
 DESCRIZIONE: Esporta i dati di una qualunque tabella/vista in formato csv
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   27/03/2020  VD      Prima emissione.
******************************************************************************/
  s_versione  varchar2(20) := 'V1.0';
  s_revisione varchar2(30) := '0    27/03/2020';
  function VERSIONE
  return varchar2;
  function F_ESISTE_COLONNA
  ( a_oggetto              varchar2
  , a_colonna              varchar2
  ) return number;
  procedure INSERT_FTP_LOG
  ( a_messaggio             varchar2
  );
  procedure INSERT_FTP_TRASMISSIONI
  ( a_clob_file             clob
  );
  procedure UPDATE_FTP_TRASMISSIONI
  ( a_clob_file             clob
  );
  procedure CREA_CLOB
  ( a_oggetto               varchar2
  , a_separatore            varchar2 default ';'
  , a_ordinamento           varchar2 default ''
  );
  procedure ESEGUI
  ( a_oggetto               varchar2
  , a_nome_file             varchaR2
  , a_separatore            varchar2 default ';'
  , a_ordinamento           varchar2 default ''
  , a_utente                varchar2
  , a_se_riga_int           varchar2 default ''
  );
end ESPORTA_STANDARD;
/

create or replace package body ESPORTA_STANDARD is
/******************************************************************************
 NOME:        ESPORTA_STANDARD
 DESCRIZIONE: Esporta i dati di una qualunque tabella/vista in formato csv
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   27/03/2020  VD      Prima emissione.
******************************************************************************/
  p_id_documento           number;
  p_sequenza               number;
  p_contarighe             number;
  p_nome_file              varchar2(100);
  p_file_clob              clob;
  p_utente                 varchar2(8);
  p_se_riga_int            varchar2(1);
  p_riga_int               varchar2(32767);
-------------------------------------------------------------------------------
  function VERSIONE return varchar2
  is
  begin
    return s_versione||'.'||s_revisione;
  end versione;
--------------------------------------------------------------------------------
  function F_ESISTE_COLONNA
  ( a_oggetto              varchar2
  , a_colonna              varchar2
  ) return number is
  /******************************************************************************
   NOME:        F_ESISTE_COLONNA
   DESCRIZIONE: Verifica se la colonna indicata come ordinamento esiste
                nell'oggetto da trattare
   PARAMETRI:   a_oggetto              Nome della tabella/vista da estrarre
                a_colonna              Nome della colonna di cui si vuole
                                       verificare l'esistenza nella tabella/vista
   NOTE:
  ******************************************************************************/
  w_result                             number;
  begin
    begin
      select 1
        into w_result
        from user_tab_columns
       where table_name = upper(a_oggetto)
         and column_name = upper(a_colonna);
    exception
      when others then
        w_result := 0;
    end;
  --
    return w_result;
  --
  end f_esiste_colonna;
--------------------------------------------------------------------------------
  procedure INSERT_FTP_LOG
  ( a_messaggio             IN     varchar2
  ) is
  /******************************************************************************
   NOME:        INSERT_FTP_LOG
   DESCRIZIONE: Inserimento tabella di Log (FTP_LOG).
   PARAMETRI:   a_messaggio         Descrizione operazione eseguita.
   NOTE:
  ******************************************************************************/
  begin
    p_sequenza := p_sequenza + 1;
    --
    -- Inserimento log
    --
    begin
      insert into ftp_log ( id_documento
                          , sequenza
                          , messaggio
                          , utente
                          , data_variazione
                          )
      values ( p_id_documento
             , p_sequenza
             , a_messaggio
             , p_utente
             , sysdate
             );
    exception
      when others then
        raise_application_error(-20999,'Errore in inserimento LOG: '||sqlerrm);
    end;
  --
    COMMIT;
  --
  end insert_ftp_log;
--------------------------------------------------------------------------------
  procedure INSERT_FTP_TRASMISSIONI
  ( a_clob_file             IN     clob
  ) is
  /******************************************************************************
   NOME:        INSERT_FTP_TRASMISSIONI
   DESCRIZIONE: Inserimento tabella file da trasmettere (FTP_TRASMISSIONI).
   PARAMETRI:   a_clob_file         clob contenente il file da inviare
   NOTE:
  ******************************************************************************/
  begin
    begin
      insert into ftp_trasmissioni ( id_documento
                                   , nome_file
                                   , clob_file
                                   , utente
                                   , data_variazione
                                   , direzione
                                   )
      values ( p_id_documento
             , p_nome_file
             , a_clob_file
             , p_utente
             , trunc(sysdate)
             , 'U'
             );
    exception
      when others then
        insert_ftp_log(substr('Insert FTP_TRASMISSIONI : '||sqlerrm,1,2000));
    end;
  end insert_ftp_trasmissioni;
--------------------------------------------------------------------------------
  procedure UPDATE_FTP_TRASMISSIONI
  ( a_clob_file             IN     clob
  ) is
  /******************************************************************************
   NOME:        UPDATE_FTP_TRASMISSIONI
   DESCRIZIONE: Aggiornamento clob in tabella file da trasmettere
                (FTP_TRASMISSIONI).
   PARAMETRI:   p_clob_file         clob contenente il file da inviare
   NOTE:
  ******************************************************************************/
  begin
    begin
      update ftp_trasmissioni
         set clob_file = a_clob_file
       where id_documento = p_id_documento
         and nome_file = p_nome_file
         and direzione = 'U';
    exception
      when others then
        insert_ftp_log(substr('Update FTP_TRASMISSIONI : '||sqlerrm,1,2000));
    end;
  end update_ftp_trasmissioni;
-------------------------------------------------------------------------------
  procedure CREA_CLOB
/******************************************************************************
 NOME:        CREA_CLOB
 DESCRIZIONE: Dato il nome di una tabella o di una vista, compone un csv con
              tutti i dati presenti nella tabella/vista indicata e lo
              memorizza in una variabile di tipo clob.
 PARAMETRI:
 NOTE:
******************************************************************************/
  ( a_oggetto              varchar2
  , a_separatore           varchar2 default ';'
  , a_ordinamento          varchar2 default ''
  ) is
    w_esiste_oggetto       number;
    w_inizio               number;
    w_nome_campo           varchar2(32767);
    w_ordinamento          varchar2(32767);
    w_stringa_select       clob;
    w_stringa_campo        varchar2(32767);
    w_stringa_ordinamento  varchar2(32767);
    w_cur_select           integer;
    w_execute              integer;
    w_result               clob;
  begin
    -- Si controlla che l'oggetto indicato esista nel DB
    begin
      select 1
        into w_esiste_oggetto
        from user_objects
       where object_name = upper(a_oggetto)
         and object_type in ('TABLE','VIEW');
    exception
      when others then
        w_esiste_oggetto := 0;
    end;
    --
    if w_esiste_oggetto = 0 then
       insert_ftp_log('Oggetto '||a_oggetto||' non esistente nel DataBase o di tipo non previsto');
       goto fine;
    end if;
    -- Si controlla che il valore indicato nel parametro ordinamento sia corretto
    w_ordinamento := upper(a_ordinamento);
    w_stringa_ordinamento := '';
    if w_ordinamento is not null then
       -- Determinazione del campo (o dei campi) di PK per ottenere l'ordinamento
       if w_ordinamento = 'S' then     -- ordinamento per PK
          for cam_pk in (select x.column_name
                              , x.position
                              , t.data_type
                           from user_constraints c
                              , user_cons_columns x
                              , user_tab_columns t
                          where c.table_name = upper(a_oggetto)
                            and c.constraint_type = 'P'
                            and c.constraint_name = x.constraint_name
                            and c.table_name = t.table_name
                            and x.column_name = t.column_name
                          order by x.position)
          loop
            if cam_pk.position = 1 then
               w_stringa_ordinamento := w_stringa_ordinamento || cam_pk.column_name;
            else
               w_stringa_ordinamento := w_stringa_ordinamento || ',' || cam_pk.column_name;
            end if;
          end loop;
       else
          w_inizio := 1;
          while w_inizio > 0
          loop
            if instr(w_ordinamento,',',w_inizio) = 0 then
               w_nome_campo := trim(substr(w_ordinamento,w_inizio));
            else
               w_nome_campo := trim(substr(w_ordinamento,w_inizio,instr(w_ordinamento,',',w_inizio) - w_inizio));
            end if;
            --
            w_esiste_oggetto := esporta_standard.f_esiste_colonna(a_oggetto,w_nome_campo);
            if w_esiste_oggetto = 1 then
               if w_stringa_ordinamento is null then
                  w_stringa_ordinamento := w_stringa_ordinamento || w_nome_campo;
               else
                  w_stringa_ordinamento := w_stringa_ordinamento || ',' || w_nome_campo;
               end if;
            end if;
            w_inizio := instr(w_ordinamento,',',w_inizio);
            if instr(w_ordinamento,',',w_inizio) > 0 then
               w_inizio := w_inizio + 1;
            end if;
          end loop;
          if nvl(w_stringa_ordinamento,'*') <> nvl(trim(replace(w_ordinamento,' ','')),'*') then
             insert_ftp_log('Ordinamento "'||a_ordinamento||'" non corretto, ordinamento utilizzato "'||
                            w_stringa_ordinamento||'"');
          end if;
       end if;
    end if;
    -- Si compone la stringa di select per selezionare tutti i campi della tabella
    -- indicata separati da ;
    w_stringa_select := 'select ';
    p_riga_int       := '';
    p_contarighe     := 0;
    for cam_tab in (select column_name
                         , data_type
                         , column_id
                      from user_tab_columns
                     where table_name = upper(a_oggetto)
                     order by column_id
                   )
    loop
      p_riga_int := p_riga_int||cam_tab.column_name||a_separatore;
      -- Se il campo è di tipo DATE, lo si converte nel formato AAAAMMGG
      if cam_tab.data_type = 'DATE' then
         w_stringa_campo := 'to_char('||cam_tab.column_name||',''yyyymmdd'')';
      elsif
         cam_tab.data_type = 'VARCHAR2' then
         w_stringa_campo := 'replace('||cam_tab.column_name||',chr(13)||chr(10),'' '')';
      else
         w_stringa_campo := cam_tab.column_name;
      end if;
      --
      if cam_tab.column_id = 1 then
         w_stringa_select := w_stringa_select || w_stringa_campo;
      else
         w_stringa_select := w_stringa_select || '||''' || a_separatore || '''||' || w_stringa_campo;
      end if;
    end loop;
    --
    w_stringa_select := w_stringa_select || '||''' || a_separatore ||''' from ' || a_oggetto;
    if w_stringa_ordinamento is not null then
       w_stringa_select := w_stringa_select || ' order by ' || w_stringa_ordinamento;
    end if;
    -- Esecuzione della stringa di sql dinamico
    if p_se_riga_int = 'S' then
       p_file_clob := p_riga_int||chr(13)||chr(10);
    else
       p_file_clob := '';
    end if;
    w_result    := '';
    w_cur_select := dbms_sql.open_cursor;
    insert_ftp_log(substr(w_stringa_select,1,2000));
    commit;
    begin
      dbms_sql.parse(w_cur_select, w_stringa_select, dbms_sql.native);
    exception
      when others then
        insert_ftp_log(substr(w_stringa_select,1,2000));
        commit;
    end;
    dbms_sql.define_column(w_cur_select, 1, w_result);
    w_execute := dbms_sql.execute(w_cur_select);
    loop
      if dbms_sql.fetch_rows(w_cur_select) > 0 then
         dbms_sql.column_value(w_cur_select, 1, w_result);
         p_file_clob := p_file_clob || w_result || chr(13)||chr(10);
         p_contarighe := p_contarighe + 1;
      else
         exit;
      end if;
    end loop;
    dbms_sql.close_cursor(w_cur_select);
  --
  if DBMS_LOB.GETLENGTH(p_file_clob) = 0 then
     insert_ftp_log('File CLOB vuoto');
  end if;
  << fine >>
    null;
  end crea_clob;
--------------------------------------------------------------------------------
  procedure ESEGUI
  ( a_oggetto               varchar2
  , a_nome_file             varchaR2
  , a_separatore            varchar2 default ';'
  , a_ordinamento           varchar2 default ''
  , a_utente                varchar2
  , a_se_riga_int           varchar2 default ''
  ) is
    w_separatore            varchar2(1);
    w_messaggio             varchar2(2000);
    errore                  exception;
  begin
    -- Estrazione per FTP:
    -- assegnazione id. per inserimento ftp_log e ftp_trasmissioni
    -- Inserimento riga in tabella ftp_trasmissioni per reference a ftp_log
    -- Inserimento inizio elaborazione in tabella FTP_LOG
    p_nome_file    := nvl(a_nome_file,a_oggetto||'.csv');
    w_separatore   := nvl(a_separatore,';');
    p_se_riga_int  := nvl(a_se_riga_int,'N');
    p_utente       := a_utente;
    p_id_documento := to_number(null);
    p_sequenza     := 0;
    ftp_trasmissioni_nr(p_id_documento);
    insert_ftp_trasmissioni(p_file_clob);
    insert_ftp_log('Inizio estrazione '||a_oggetto||': '||to_char(sysdate,'dd/mm/yyyy hh24.mi.ss'));
    commit;
    esporta_standard.crea_clob(a_oggetto,w_separatore,a_ordinamento);
    update_ftp_trasmissioni(p_file_clob);
    insert_ftp_log('Fine estrazione '||a_oggetto||': '||to_char(sysdate,'dd/mm/yyyy hh24.mi.ss')||
                   ', Righe inserite '||p_contarighe);
    commit;
  exception
    when errore then
      raise_application_error(-20999, w_messaggio);
  end esegui;
end ESPORTA_STANDARD;
/

