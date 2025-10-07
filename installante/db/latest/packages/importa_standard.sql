--liquibase formatted sql 
--changeset abrandolini:20250326_152429_importa_standard stripComments:false runOnChange:true 
 
create or replace package IMPORTA_STANDARD is
/******************************************************************************
 NOME:        IMPORTA_STANDARD
 DESCRIZIONE: Procedure e Funzioni per caricamento di una qualunque tabella.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   31/03/2020  VD      Prima emissione.
 *****************************************************************************/
  function F_GET_CLOB
  ( a_nome_file             varchar2
  ) return number;
  function F_CHECK_TABELLA
  ( a_tabella                varchar2
  , a_prima_riga             varchar2
  , a_separatore             varchar2
  ) return number;
  procedure VUOTA_TABELLA
  ( a_tabella            varchar2
  );
  procedure INSERT_FTP_TRASMISSIONI
  ( a_clob_file             clob
  );
  procedure INSERT_FTP_LOG
  ( a_messaggio             varchar2
  );
  procedure ESEGUI
  ( a_nome_file             varchar2
  , a_nome_tabella          varchar2
  , a_utente                varchar2
  , a_separatore            varchar2 default null
  , a_se_vuota_tabella      varchar2 default null
  );
end IMPORTA_STANDARD;
/

create or replace package body IMPORTA_STANDARD is
/******************************************************************************
 NOME:        IMPORTA_STANDARD
 DESCRIZIONE: Procedure e Funzioni per caricamento di una qualunque tabella.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   31/03/2020  VD      Prima emissione.
 *****************************************************************************/
p_nome_file                varchar2(100);
p_utente                   varchar2(8);
p_separatore               varchar2(1);
p_se_vuota_tabella         varchar2(1);
p_id_documento             number;
p_documento_clob           clob;
p_dimensione_file          number;
p_lunghezza_riga           number;
p_posizione_old            number;
p_posizione                number;
p_stringa_insert1          clob;
p_stringa_insert2          clob;
p_sequenza                 number;
type type_nomi_campo       is table of varchar2(30) index by binary_integer;
t_nome_campo               type_nomi_campo;
type type_val_campo        is table of varchar2(1) index by binary_integer;
t_validita_campo           type_val_campo;
type type_tipo_campo       is table of varchar2(20) index by binary_integer;
t_tipo_campo               type_tipo_campo;
type type_lunghezza_campo  is table of number index by binary_integer;
t_lunghezza_campo          type_lunghezza_campo;
p_ind                      number;
errore                     exception;
-------------------------------------------------------------------------------
function F_GET_CLOB
/******************************************************************************
 NOME:        F_GET_CLOB
 DESCRIZIONE: Recupera il file da caricare dalla tabella FTP_TRASMISSIONI
 NOTE:        -
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   31/03/2020  VD      Prima emissione.
 *****************************************************************************/
( a_nome_file              varchar2
) return number
is
begin
-- Si determina l'ultimo file caricato
  begin
    select max(id_documento)
      into p_id_documento
      from ftp_trasmissioni
     where nome_file = a_nome_file
       and direzione = 'E'
     group by nome_file, direzione;
  exception
    when others then
      p_id_documento := to_number(null);
  end ;
  -- Se il file da caricare non esiste, si registra un messaggio in ftp_log
  -- con id. documento negativo
  if p_id_documento is null then
     select least(nvl(min(p_id_documento),0),0)
       into p_id_documento
       from ftp_trasmissioni;
     p_id_documento   := nvl(p_id_documento,0) -1;
     p_documento_clob := '';
     p_sequenza       := 0;
     importa_standard.insert_ftp_trasmissioni(p_documento_clob);
     importa_standard.insert_ftp_log(a_nome_file||' - Non esistono file da caricare');
     return 0;
  end if;
  -- Si seleziona la max(sequenza) utilizzata in FTP_LOG per il file da trattare
  begin
    select nvl(max(sequenza),0)
      into p_sequenza
      from ftp_log
     where id_documento = p_id_documento
     group by id_documento;
  exception
    when others then
      p_sequenza := 0;
  end;
  -- Inserimento log di inizio elaborazione
  insert_ftp_log('Inizio estrazione '||a_nome_file||': '||to_char(sysdate,'dd/mm/yyyy hh24.mi.ss'));
  commit;
  -- Estrazione BLOB
  begin
     select clob_file
       into p_documento_clob
       from ftp_trasmissioni
      where id_documento = p_id_documento;
  exception
    when others then
      importa_standard.insert_ftp_log(substr('File '||a_nome_file||' non caricato - '||sqlerrm,1,2000));
      return 0;
  end;
  -- Si controlla la dimensione del file selezionato
  p_dimensione_file:= DBMS_LOB.GETLENGTH(p_documento_clob);
  if nvl(p_dimensione_file,0) = 0 then
     importa_standard.insert_ftp_log('Attenzione! File '||a_nome_file||' vuoto');
     return 0;
  end if;
  --
  return 1;
end F_GET_CLOB;
-------------------------------------------------------------------------------
function F_CHECK_TABELLA
/******************************************************************************
 NOME:        F_CHECK_TABELLA
 DESCRIZIONE: Controlla l'esistenza della tabella e dei campi indicati
              nell'intestazione del file.
 NOTE:        -
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   31/03/2020  VD      Prima emissione.
 *****************************************************************************/
( a_tabella                varchar2
, a_prima_riga             varchar2
, a_separatore             varchar2
) return number
is
  w_esiste_oggetto         number;
  w_nome_campo             varchar2(30);
  w_tipo_campo             varchar2(20);
  w_lunghezza_campo        number;
  w_riga_valida            varchar2(1);
begin
  -- Si controlla che la tabella indicata esista nel DB
  begin
    select 1
      into w_esiste_oggetto
      from user_objects
     where object_name = upper(a_tabella)
       and object_type = 'TABLE';
  exception
    when others then
      w_esiste_oggetto := 0;
  end;
  --
  if nvl(w_esiste_oggetto,0) = 0 then
     insert_ftp_log('Tabella '||a_tabella||' non esistente nel DataBase');
     return 0;
  end if;
  -- Si compone l'array contenente i nomi dei campi della tabella
  -- ricavato dalla prima riga del file
  begin
    p_posizione_old  := 1;
    p_posizione      := 1;
    p_lunghezza_riga := DBMS_LOB.GETLENGTH(a_prima_riga);
    p_ind            := 0;
    --
    while p_posizione_old < p_lunghezza_riga
    loop
      p_posizione      := instr (a_prima_riga, a_separatore, p_posizione_old);
      if p_posizione = 0 then
         p_posizione := p_lunghezza_riga + 1;
      end if;
      w_nome_campo     := substr (a_prima_riga, p_posizione_old, p_posizione-p_posizione_old);
      p_posizione_old  := p_posizione + 1;
      -- Si verifica se il nome di campo estratto esiste nella tabella indicata
      begin
        select decode(data_type
                     ,'VARCHAR2',data_type
                     ,'NUMBER',data_type
                     ,'DATE',data_type
                     ,'')
             , decode(data_type
                     ,'VARCHAR2',data_length
                     ,'NUMBER',data_precision
                     ,to_number(null))
          into w_tipo_campo
             , w_lunghezza_campo
          from user_tab_columns
         where table_name = upper(a_tabella)
           and column_name = upper(w_nome_campo);
      exception
        when others then
          w_tipo_campo      := '';
          w_lunghezza_campo := to_number(null);
      end;
      --
      p_ind := p_ind + 1;
      t_nome_campo(p_ind) := w_nome_campo;
      t_tipo_campo(p_ind) := w_tipo_campo;
      t_lunghezza_campo(p_ind) := w_lunghezza_campo;
      if w_tipo_campo is null then
         t_validita_campo(p_ind) := 'N';
      else
         t_validita_campo(p_ind) := 'S';
      end if;
    end loop;
    -- controllo dei campi: se tutti i campi NON sono validi, significa che manca la riga di intestazione
    w_riga_valida := '';
    for p_ind in t_nome_campo.first .. t_nome_campo.last
    loop
      if t_validita_campo(p_ind) = 'S' then
         w_riga_valida := 'S';
      end if;
    end loop;
    if w_riga_valida is null then
       importa_standard.insert_ftp_log('Riga intestazione mancante o dati non presenti nella tabella da valorizzare');
       w_esiste_oggetto := 0;
    else
       -- composizione della prima parte della stringa di insert
       p_stringa_insert1 := 'Insert into '||a_tabella||' (';
       for p_ind in t_nome_campo.first .. t_nome_campo.last
       loop
         if substr(p_stringa_insert1,-1) = '(' then
            p_stringa_insert1 := p_stringa_insert1||t_nome_campo(p_ind);
         else
            p_stringa_insert1 := p_stringa_insert1||','||t_nome_campo(p_ind);
         end if;
       end loop;
       p_stringa_insert1 := p_stringa_insert1||')';
    end if;
  exception
    when others then
      importa_standard.insert_ftp_log(substr('Errore in composizione stringa insert '||a_tabella||
                                      '( '||sqlerrm||')',1,2000));
      w_esiste_oggetto := 0;
  end;
--
  importa_standard.insert_ftp_log(p_stringa_insert1);
  return w_esiste_oggetto;
--
end F_CHECK_TABELLA;
--------------------------------------------------------------------------------
procedure VUOTA_TABELLA
/******************************************************************************
 NOME:        VUOTA_TABELLA
 DESCRIZIONE: Esegue la truncate della tabella indicata.
 PARAMETRI:   a_tabella    Nome della tabella da troncare.
 NOTE:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   31/03/2020  VD      Prima emissione.
******************************************************************************/
( a_tabella            varchar2
) is
  w_cursor_truncate      integer;
  w_execute              integer;
  w_stringa_truncate     varchar2(2000);
begin
   w_cursor_truncate    := dbms_sql.OPEN_CURSOR;
   w_stringa_truncate   := 'truncate table '||a_tabella;
   dbms_sql.parse(w_cursor_truncate, w_stringa_truncate, dbms_sql.native);
   w_execute          := dbms_sql.execute(w_cursor_truncate);
   dbms_sql.close_cursor(w_cursor_truncate);
end VUOTA_TABELLA;
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
        raise_application_error(-20999,'Ins. FTP_TRASMISSIONI: '||p_id_documento||
                                       ' ('||sqlerrm||')');
    end;
  end insert_ftp_trasmissioni;
--------------------------------------------------------------------------------
procedure INSERT_FTP_LOG
( a_messaggio             IN     varchar2
) is
/******************************************************************************
 NOME:        INSERT_FTP_LOG
 DESCRIZIONE: Inserimento tabella di Log (FTP_LOG).
 PARAMETRI:   a_messaggio         Descrizione operazione eseguita.
 NOTE:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   31/03/2020  VD      Prima emissione.
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
-------------------------------------------------------------------------------
procedure ESEGUI
( a_nome_file             varchar2
, a_nome_tabella          varchar2
, a_utente                varchar2
, a_separatore            varchar2 default null
, a_se_vuota_tabella      varchar2 default null
) is
  w_prima_riga            clob;
  w_riga                  clob;
  w_righe_lette           number;
  w_righe_scritte         number;
  w_riga_posizione        number;
  w_riga_posizione_old    number;
  w_riga_lunghezza        number;
  w_valore_campo          varchar2(4000);
  w_ind                   number;
  w_messaggio_log         varchar2(2000);
  w_cursor_insert        integer;
  w_execute              integer;
begin
  -- Valorizzazione variabili di package
  p_nome_file        := a_nome_file;
  p_utente           := upper(a_utente);
  p_separatore       := nvl(a_separatore,';');
  p_se_vuota_tabella := nvl(upper(a_se_vuota_tabella),'N');
  -- Si scarica il file in una variabile CLOB e si controlla che sia tutto OK
  if f_get_clob(a_nome_file) = 0 then
     raise errore;
  end if;
  -- Si estrae la prima riga del CLOB per controllare la presenza dei campi
  -- nella tabella
  p_posizione_old  := 1;
  p_posizione      := instr (p_documento_clob, chr (10), p_posizione_old);
  w_prima_riga     := substr(p_documento_clob,p_posizione_old,p_posizione-p_posizione_old);
  if f_check_tabella (a_nome_tabella,w_prima_riga,p_separatore) = 0 then
     raise errore;
  end if;
  -- Se richiesto, si esegue la truncate della tabella
  if p_se_vuota_tabella = 'S' then
     importa_standard.vuota_tabella(a_nome_tabella);
  end if;
  --
  w_cursor_insert  := dbms_sql.open_cursor;
  w_righe_lette    := 0;
  w_righe_scritte  := 0;
  p_posizione_old  := instr (p_documento_clob, chr (10)) + 1;
  p_posizione      := 1;
  p_ind            := 1;
  -- Si scorre il clob riga per riga
  while p_posizione < p_dimensione_file
  loop
    p_posizione            := instr (p_documento_clob, chr (10), p_posizione_old);
    --dbms_output.put_line('Posizione: '||p_posizione||', Posizione old: '||p_posizione_old);
    w_riga                 := substr (p_documento_clob, p_posizione_old, p_posizione-p_posizione_old-1);
    p_posizione_old        := p_posizione + 1;
    w_righe_lette          := w_righe_lette + 1;
    --
    w_riga_posizione_old   := 1;
    w_riga_posizione       := 1;
    w_riga_lunghezza       := DBMS_LOB.GETLENGTH(w_riga);
    --dbms_output.put_line('w_riga: '||w_riga||', Lunghezza riga: '||w_riga_lunghezza);
    w_ind                  := 0;
    w_messaggio_log        := '';
    p_stringa_insert2      := ' values (';
    -- Per ogni riga si compone la restante parte della stringa
    -- di insert e si inserisce un record nella tabella
    while w_riga_posizione_old <= w_riga_lunghezza
    loop
      w_riga_posizione     := instr (w_riga, p_separatore, w_riga_posizione_old);
      if w_riga_posizione = 0 then
         w_riga_posizione  := w_riga_lunghezza + 1;
      end if;
      --dbms_output.put_line('Posizione riga: '||w_riga_posizione||', Posizione old riga: '||w_riga_posizione_old);
      w_valore_campo       := trim(substr(w_riga, w_riga_posizione_old,w_riga_posizione-w_riga_posizione_old));
      w_riga_posizione_old := w_riga_posizione + 1;
      w_ind := w_ind + 1;
      --dbms_output.put_line('Valore campo: '||w_valore_campo);
      --dbms_output.put_line('w_ind: '||w_ind);
      --dbms_output.put_line('Nome campo: '||t_nome_campo(w_ind));
      --dbms_output.put_line('Tipo campo: '||t_tipo_campo(w_ind));
      --dbms_output.put_line('Validità campo: '||t_validita_campo(w_ind));
      if t_validita_campo(w_ind) = 'S' then
         if t_tipo_campo(w_ind) = 'VARCHAR2' then
            if length(w_valore_campo) > t_lunghezza_campo(w_ind) then
               w_valore_campo :='substr('''||w_valore_campo||''',1,'||t_lunghezza_campo(w_ind)||''')';
               w_messaggio_log := 'Eccedenza dimensione campo '||t_nome_campo(w_ind)||': '||length(w_valore_campo)||
                                  ', dimensione prevista: '||t_lunghezza_campo(w_ind);
            else
               w_valore_campo := ''''||replace(w_valore_campo,'''','''''')||'''';
            end if;
         elsif
            t_tipo_campo(w_ind) = 'NUMBER' then
            if length(to_number(replace(replace(w_valore_campo,'.',''),'-',''))) > t_lunghezza_campo(w_ind) then
               w_valore_campo := null;
               w_messaggio_log := 'Eccedenza dimensione campo '||t_nome_campo(w_ind)||': '||
                                  length(to_number(replace(replace(w_valore_campo,'.',''),'-','')))||
                                  ', dimensione prevista: '||t_lunghezza_campo(w_ind);
            else
               w_valore_campo := 'to_number('''||w_valore_campo||''')';
            end if;
         elsif
            t_tipo_campo(w_ind) = 'DATE' then
            begin
              w_valore_campo := 'to_date('''||w_valore_campo||''',''yyyymmdd'')';
            exception
              when others then
                w_messaggio_log := 'Campo '||t_nome_campo(w_ind)||': '||
                                   'Formato data non previsto (Il formato deve essere AAAAMMGG)';
                w_valore_campo := 'NULL';
            end;
         else
            w_valore_campo := 'NULL';
         end if;
      else
         w_valore_campo := 'NULL';
      end if;
      --
      if w_messaggio_log is not null then
         importa_standard.insert_ftp_log(w_messaggio_log);
         w_messaggio_log := '';
      end if;
      -- Se l'ultimo carattere della seconda stringa di insert è "(",
      -- significa che stiamo inserendo il primo campo dell'elenco
      -- quindi non bisogna mettere la virgola
      if substr(p_stringa_insert2,-1) = '(' then
         p_stringa_insert2 := p_stringa_insert2||w_valore_campo;
      else
         p_stringa_insert2 := p_stringa_insert2||','||w_valore_campo;
      end if;
    end loop;
    p_stringa_insert2 := p_stringa_insert2||')';
    -- Si inserisce la riga nella tabella prevista
    begin
      dbms_sql.parse(w_cursor_insert,p_stringa_insert1||p_stringa_insert2,dbms_sql.native);
      w_execute:= dbms_sql.execute(w_cursor_insert);
      w_righe_scritte := w_righe_scritte + 1;
    exception
      when others then
        importa_standard.insert_ftp_log(p_stringa_insert2);
        w_messaggio_log := substr('Ins. riga n.: '||w_righe_lette||' - '||sqlerrm,1,2000);
        importa_standard.insert_ftp_log(w_messaggio_log);
    end;
  end loop;
  --
  dbms_sql.close_cursor(w_cursor_insert);
  insert_ftp_log('Fine elaborazione '||a_nome_file||': '||to_char(sysdate,'dd/mm/yyyy hh24.mi.ss')||
                 ', Nome tabella: '||a_nome_tabella||
                 ', Righe trattate: '||w_righe_lette||', Righe inserite: '||w_righe_scritte);
  commit;
exception
  when errore then
    null;
  when others then
    raise_application_error(-20999,sqlerrm);
end ESEGUI;
end IMPORTA_STANDARD;
/

