--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_dic_successioni stripComments:false runOnChange:true 
 
create or replace procedure CARICA_DIC_SUCCESSIONI
/*************************************************************************
 NOME:        CARICA_DIC_SUCCESSIONI
 DESCRIZIONE: Carica i dati dei file di successione nelle relative
              tabelle di appoggio
 NOTE:        A_CTR_DENUNCIA assume i seguenti valori:
              'S' - controlla se esiste gia' una denuncia per il
                    contribuente da trattare
              'N' - Inserisce sempre una nuova denuncia
              A_SEZIONE_UNICA assume i seguenti valori:
              'S' - per il trattamento dei dati catastali si considera la
                    sezione = null
              'N' - per il trattamento dei dati catastali si considera la
                    sezione presente sul file
  Rev.    Date         Author      Note
  6       14/03/2022   DM          Gestione stato 15
  5       05/06/2020   VD          Corretta gestione decimali: si seleziona
                                   prima il parametro di sessione
                                   NLS_NUMERIC_CHARACTERS e in base a tale
                                   parametro si decide come gestire il
                                   separatore dei decimali
  4       27/05/2020   AB          Corretta gestione decimali tenendo conto
                                   del parametro nls_language di Oracle
  3       19/03/2019   VD          Corretta gestione nuovo record
                                   contenente il valore dell'immobile.
                                   Ora si gestiscono entrambi i casi,
                                   sia che i dati dell'immobile siano
                                   su un'unica riga, sia che siano su
                                   2 righe.
  2       23/11/2018   VD          Aggiunta gestione nuovo record
                                   contenente il valore dell'immobile
  1       12/05/2017   VD          Aggiunti commenti
  0       22/12/2009   XX          Prima emissione
*************************************************************************/
( a_documento_id     in      number
, a_utente           in      varchar2
, a_ctr_denuncia     in      varchar2
, a_sezione_unica    in      varchar2
, a_fonte            in      number
, a_messaggio        in out  varchar2
)
is
-- w_commenti abilita le dbms_output, può avere i seguenti valori:
--  0  =   Nessun Commento
--  1  =   Commenti principali Ablitati
w_commenti                number := 0;
w_documento_blob          blob;
w_number_temp             number;
w_numero_righe            number;
w_riga                    varchar2(252);
w_comune                  varchar2(4);
w_comune_dage             varchar2(4);
w_descrizione_comune      varchar2(40);
w_presenza_record         varchar2(1) := 'S';
w_tipo_record             varchar2(1);
w_successione             number(10);
w_stato_successione       successioni_defunti.stato_successione%type;
w_num_successioni         number := 0;
w_num_succ_gia_inserite   number := 0;
w_num_pratiche            number := 0;
w_num_nuovi_oggetti       number := 0;
w_num_nuovi_contribuenti  number := 0;
w_num_nuovi_soggetti      number := 0;
w_pratiche_gia_inserite   number := 0;
w_errore                  varchar(2000) := NULL;
errore                    exception;
sql_errm                  varchar2(100);
-- (VD - 23/11/2018): Variabili per gestione valore immobile
w_cf_defunto              varchar2(16);
w_progr_immobile          number;
w_valore                  number;
-- (VD - 05/06/2020): Variabili per gestione separatore decimali
w_da_sostituire            varchar2(1);
w_sostituto                varchar2(1);
PROCEDURE crea_sutd (
   p_successione         NUMBER,
   p_tipo_tributo        VARCHAR2,
   p_stato_successione   VARCHAR2
)
AS
DUPLICATO_EXCEPTION EXCEPTION;
PRAGMA EXCEPTION_INIT(DUPLICATO_EXCEPTION, -20007);
BEGIN
   INSERT INTO successioni_tributo_defunti
               (successione,
                stato_successione,
                tipo_tributo
               )
        VALUES (p_successione,
                DECODE (p_stato_successione,
                        'P', 'DA GESTIRE',
                        'I', 'DA GESTIRE',
                        'NON GESTIBILI'
                       )                                  -- stato successione
                        ,
                p_tipo_tributo);
EXCEPTION
   WHEN DUPLICATO_EXCEPTION THEN
      NULL;
   WHEN OTHERS
   THEN
      sql_errm := SUBSTR (SQLERRM, 1, 100);
      w_errore :=
            'Errore in inserimento successioni_tributo_defunti '
         || p_tipo_tributo
         || ' '
         || ' ('
         || sql_errm
         || ')';
      RAISE errore;
END crea_sutd;
PROCEDURE crea_sute (
   p_successione         NUMBER,
   p_tipo_tributo        VARCHAR2,
   p_progressivo         NUMBER
)
AS
DUPLICATO_EXCEPTION EXCEPTION;
PRAGMA EXCEPTION_INIT(DUPLICATO_EXCEPTION, -20007);
BEGIN
   INSERT INTO successioni_tributo_eredi
               (successione,
                tipo_tributo, progressivo
               )
        VALUES (p_successione,
                p_tipo_tributo, p_progressivo);
EXCEPTION
   WHEN DUPLICATO_EXCEPTION THEN
      NULL;
   WHEN DUP_VAL_ON_INDEX THEN
      NULL;
   WHEN OTHERS
   THEN
      sql_errm := SUBSTR (SQLERRM, 1, 100);
      w_errore :=
            'Errore in inserimento successioni_tributo_eredi '
         || p_tipo_tributo
         || ' '
         || ' ('
         || sql_errm
         || ')';
      RAISE errore;
END crea_sute;
/*-------------------------------------------------------------------*/
/*CARICAMENTO*/
/*-------------------------------------------------------------------*/
begin
   if w_commenti > 0 then
     DBMS_OUTPUT.Put_Line('---- Inizio ----');
   end if;
   -- Cambio stato in caricamento in corso per gestione Web
   update documenti_caricati
           set stato = 15
             , data_variazione = sysdate
             , utente = a_utente
         where documento_id = a_documento_id
             ;
   commit;
-- (VD - 05/06/2020): Selezione del parametro NLS_NUMERIC_CHARACTERS
   begin
     select decode(substr(value,1,1)
                  ,'.',',','.')
          , substr(value,1,1)
       into w_da_sostituire
          , w_sostituto
       from nls_session_parameters
      where parameter = 'NLS_NUMERIC_CHARACTERS';
   exception
     when others then
       w_da_sostituire := ',';
       w_sostituto := '.';
   end;
   -- Estrazione comune dati generali
   begin
      select comu.sigla_cfis
        into w_comune_dage
        from dati_generali dage
           , ad4_comuni comu
       where dage.com_cliente = comu.comune
         and dage.pro_cliente = comu.provincia_stato
           ;
   EXCEPTION
    WHEN others THEN
       sql_errm  := substr(SQLERRM,1,100);
       w_errore := 'Errore in recupero comune dati_generali '||
                   ' ('||sql_errm||')';
       raise errore;
   end;
  DBMS_LOB.createtemporary (lob_loc =>   w_documento_blob
                              ,cache =>     true
                              ,dur =>       DBMS_LOB.session
                              );
   -- Estrazione BLOB
   begin
      select contenuto
        into w_documento_blob
        from documenti_caricati doca
       where doca.documento_id  = a_documento_id
           ;
   end;
   -- Verifica dimensione file caricato
   w_number_temp:= DBMS_LOB.GETLENGTH(w_documento_blob);
   if nvl(w_number_temp,0) = 0 then
     w_errore := 'Attenzione File caricato Vuoto - Verificare Client Oracle';
     raise errore;
   end if;
   w_numero_righe := w_number_temp / 252;
   if w_commenti > 0 then
      DBMS_OUTPUT.Put_Line(to_char(w_numero_righe));
   end if;
   FOR i IN 0 .. w_numero_righe - 1 LOOP
      w_riga := utl_raw.cast_to_varchar2(
                      dbms_lob.substr(w_documento_blob,252, (252 * i ) + 1)
                                        );
      if w_commenti > 0 then
         DBMS_OUTPUT.Put_Line(to_char(i));
         --dbms_output.put_line(w_riga);
      end if;
      w_tipo_record := substr(w_riga,1,1);
      if w_commenti > 0 then
      dbms_output.put_line('Tipo record: '||w_tipo_record);
      end if;
      -- controllo del comune
      if w_tipo_record in ('A','B','C','D') then
         w_comune := substr(w_riga,21,4);
         if w_commenti > 0 then
         dbms_output.put_line('Comune: '||w_comune);
         end if;
         if upper(w_comune) <> upper(w_comune_dage) then
            begin
               select max(comu.denominazione)
                 into w_descrizione_comune
                 from ad4_comuni comu
                where comu.sigla_cfis = w_comune
                    ;
            EXCEPTION
             WHEN others THEN
                w_descrizione_comune :='Descrizione inesistente';
            end;
            w_errore := 'Errore: Comune Errato nei dati ('||w_comune||' Descrizione inesistente'||')';
            raise errore;
         end if;
      end if;
      -- verifica presenza successione su DB
      if w_tipo_record = 'A' then
         begin
            select 'S', successione, stato_successione
              into w_presenza_record, w_successione, w_stato_successione
              from successioni_defunti
             where ufficio     = substr(w_riga,2,3)
               and anno        = to_number('20'||substr(w_riga,5,2))
               and volume      = to_number(substr(w_riga,7,5))
               and numero      = to_number(substr(w_riga,12,6))
               and sottonumero = to_number(substr(w_riga,18,3))
               and comune      = substr(w_riga,21,4)
               ;
         EXCEPTION
          WHEN others THEN
             w_presenza_record := 'N';
         end;
         if w_presenza_record = 'S' then
            crea_sutd(w_successione, 'ICI', 'DA GESTIRE');
            crea_sutd(w_successione, 'TASI', 'DA GESTIRE');
         end if;
      end if;
      if w_presenza_record = 'N' then
         -- Inserimento Defunti
         if w_tipo_record = 'A' then
            w_successione := null;
            w_cf_defunto := rtrim(substr(w_riga,42,16));
            w_progr_immobile := -1;
            SUCCESSIONI_DEFUNTI_NR(w_successione);
            BEGIN
               insert into successioni_defunti
                      (successione
                      ,ufficio
                      ,anno
                      ,volume
                      ,numero
                      ,sottonumero
                      ,comune
                      ,tipo_dichiarazione
                      ,data_apertura
                      ,cod_fiscale
                      ,cognome
                      ,nome
                      ,sesso
                      ,citta_nas
                      ,prov_nas
                      ,data_nas
                      ,citta_res
                      ,prov_res
                      ,indirizzo
                      ,stato_successione
                      ,utente
                      )
               values (w_successione
                      ,substr(w_riga,2,3)                                          -- ufficio
                      ,to_number('20'||substr(w_riga,5,2))                         -- anno
                      ,to_number(substr(w_riga,7,5))                               -- volume
                      ,to_number(substr(w_riga,12,6))                              -- numero
                      ,to_number(substr(w_riga,18,3))                              -- sottonumero
                      ,substr(w_riga,21,4)                                         -- comune
                      ,substr(w_riga,31,1)                                         -- tipo dichiarazione
                      ,to_date(substr(w_riga,32,10),'yyyy-mm-dd')                  -- data apertura
                      ,rtrim(substr(w_riga,42,16))                                 -- CF defunto
                      ,rtrim(substr(w_riga,58,25))                                 -- cognome defunto
                      ,rtrim(substr(w_riga,83,25))                                 -- nome defunto
                      ,substr(w_riga,108,1)                                        -- sesso defunto
                      ,rtrim(substr(w_riga,109,30))                                -- citta nascita
                      ,substr(w_riga,139,2)                                        -- provincia nascita
                      ,to_date(substr(w_riga,141,10),'yyyy-mm-dd')                 -- data nascita
                      ,rtrim(substr(w_riga,151,30))                                -- citta residenza
                      ,substr(w_riga,181,2)                                        -- provincia residenza
                      ,rtrim(substr(w_riga,183,30))                                -- indirizzo
                      ,decode(substr(w_riga,31,1)
                             ,'P','DA GESTIRE'
                             ,'I','DA GESTIRE'
                             ,'NON GESTIBILI'
                             )                                                     -- stato successione
                      ,a_utente                                                    -- utente
                      )
                       ;
            EXCEPTION
             WHEN others THEN
                sql_errm  := substr(SQLERRM,1,100);
                w_errore := 'Errore in inserimento successioni_defunto '||
                            ' ('||sql_errm||')';
                raise errore;
            END;
            crea_sutd(w_successione, 'ICI', substr(w_riga,31,1));
            crea_sutd(w_successione, 'TASI', substr(w_riga,31,1));
            w_num_successioni := w_num_successioni + 1;
         -- Inserimento Eredi
         elsif w_tipo_record = 'B' then
            BEGIN
               insert into successioni_eredi
                      (successione
                      ,progressivo
                      ,progr_erede
                      ,categoria
                      ,cod_fiscale
                      ,cognome
                      ,nome
                      ,denominazione
                      ,sesso
                      ,citta_nas
                      ,prov_nas
                      ,data_nas
                      ,citta_res
                      ,prov_res
                      ,indirizzo
                      )
               values (w_successione
                      ,to_number(substr(w_riga,26,5))                              -- progressivo
                      ,to_number(substr(w_riga,31,3))                              -- progr_erede
                      ,substr(w_riga,34,1)                                         -- categoria
                      ,rtrim(substr(w_riga,35,16))                                 -- cod_fiscale erede
                      ,decode(substr(w_riga,101,1)
                             ,'S',''
                             ,rtrim(substr(w_riga,51,25) ))                        -- cognome
                      ,decode(substr(w_riga,101,1)
                             ,'S',''
                             ,rtrim(substr(w_riga,76,25) ))                        -- nome
                      ,decode(substr(w_riga,101,1)
                             ,'S',rtrim(substr(w_riga,51,50))
                             ,'' )                                                 -- denominazione
                      ,decode(substr(w_riga,101,1)
                             ,'S',''
                             ,substr(w_riga,101,1) )                               -- sesso
                      ,rtrim(substr(w_riga,102,30))                                -- citta nascita
                      ,substr(w_riga,132,2)                                        -- provincia nascita
                      ,to_date(rtrim(substr(w_riga,134,10)),'yyyy-mm-dd')          -- data nascita
                      ,rtrim(substr(w_riga,144,30))                                -- citta residenza
                      ,substr(w_riga,174,2)                                        -- provincia residenza
                      ,rtrim(substr(w_riga,176,30))                                -- indirizzo
                      )
                       ;
            EXCEPTION
             WHEN others THEN
                sql_errm  := substr(SQLERRM,1,100);
                w_errore := 'Errore in ins suer '||substr(w_riga,1,30)||
                            ' ('||sql_errm||')';
                raise errore;
            END;
            crea_sute(w_successione, 'ICI', to_number(substr(w_riga,26,5)));
            crea_sute(w_successione, 'TASI', to_number(substr(w_riga,26,5)));
         -- Inserimento Immobili
         elsif w_tipo_record = 'C' then
            if to_number(substr(w_riga,53,3)) = 0 then
               w_progr_immobile := to_number(substr(w_riga,31,3));
               w_valore := to_number(substr(w_riga,137,15)) / 100;
            else
               if to_number(substr(w_riga,31,3)) <> w_progr_immobile then
                  w_progr_immobile := to_number(substr(w_riga,31,3));
                  w_valore := to_number(null);
               end if;
               BEGIN
                  insert into successioni_immobili
                         (successione
                         ,progressivo
                         ,progr_immobile
                         ,numeratore_quota_def
                         ,denominatore_quota_def
                         ,diritto
                         ,progr_particella
                         ,catasto
                         ,sezione
                         ,foglio
                         ,particella_1
                         ,particella_2
                         ,subalterno_1
                         ,subalterno_2
                         ,denuncia_1
                         ,denuncia_2
                         ,anno_denuncia
                         ,natura
                         ,superficie_ettari
                         ,superficie_mq
                         ,vani
                         ,indirizzo
                         ,valore
                         )
   --CTGY1009990000581000D713C000010010000001,00000000101001U   0001000586  006 A2 000000000,000009,5VIA PIVARI
                  values (w_successione
                         ,to_number(substr(w_riga,26,5))                              -- progressivo
                         ,to_number(substr(w_riga,31,3))                              -- progr_immobile
                         ,to_number(translate(substr(w_riga,34,11),w_da_sostituire,w_sostituto))          -- numeratore_quota_def
                         ,to_number(substr(w_riga,45,6))                              -- denominatore_quota_def
                         ,rtrim(substr(w_riga,51,2))                                  -- diritto
                         ,to_number(substr(w_riga,53,3))                              -- progr_particella
                         ,rtrim(substr(w_riga,56,2))                                  -- catasto
                         ,rtrim(substr(w_riga,58,2))                                  -- sezione
                         ,decode(substr(w_riga,60,1)
                                ,'0',ltrim(rtrim(substr(w_riga,61,4)),'0')
                                ,'')                                                  -- foglio
                         ,decode(substr(w_riga,60,1)
                                ,'0',ltrim(rtrim(substr(w_riga,65,5)),'0')
                                ,'')                                                  -- particella_1
                         ,decode(substr(w_riga,60,1)
                                ,'0',ltrim(rtrim(substr(w_riga,70,2)),'0')
                                ,'')                                                  -- particella_2
                         ,decode(substr(w_riga,60,1)
                                ,'0',to_number(rtrim(substr(w_riga,72,3)))
                                ,null)                                                -- subalterno_1
                         ,decode(substr(w_riga,60,1)
                                ,'0',rtrim(substr(w_riga,75,1))
                                ,'')                                                  -- subalterno_2
                         ,decode(substr(w_riga,60,1)
                                ,'1',rtrim(substr(w_riga,61,7))
                                ,'')                                                  -- denuncia_1
                         ,decode(substr(w_riga,60,1)
                                ,'1',rtrim(substr(w_riga,68,3))
                                ,'')                                                  -- denuncia_2
                         ,decode(substr(w_riga,60,1)
                                ,'1',decode(sign(to_number('20'||substr(w_riga,71,2))
                                                  - to_number(to_char(sysdate,'yyyy'))
                                                 )
                                           ,1,to_number('19'||substr(w_riga,71,2))
                                           ,to_number('20'||substr(w_riga,71,2))
                                           )
                                ,null)                                                -- anno denuncia
                         ,rtrim(substr(w_riga,76,3))                                  -- natura
                         ,to_number(substr(w_riga,79,5))                              -- superficie_ettari
                         ,to_number(translate(substr(w_riga,84,8),w_da_sostituire,w_sostituto)) -- superficie MQ
                         ,to_number(translate(substr(w_riga,92,5),w_da_sostituire,w_sostituto)) -- vani
                         ,rtrim(substr(w_riga,97,40))                                 -- indirizzo
                         ,w_valore
                         )
                          ;
               EXCEPTION
                WHEN others THEN
                   sql_errm  := substr(SQLERRM,1,100);
                   w_errore := 'Errore in ins suim '||substr(w_riga,1,30)||
                               ' ('||sql_errm||')';
                   raise errore;
               END;
            end if;
         -- Inserimento Devoluzioni
         elsif w_tipo_record = 'D' then
            BEGIN
               insert into successioni_devoluzioni
                      (successione
                      ,progressivo
                      ,progr_immobile
                      ,progr_erede
                      ,numeratore_quota
                      ,denominatore_quota
                      ,agevolazione_prima_casa
                      )
               values (w_successione
                      ,to_number(substr(w_riga,26,5))                              -- progressivo
                      ,to_number(substr(w_riga,31,3))                              -- progr_immobile
                      ,to_number(substr(w_riga,34,3))                              -- progr_erede
                      ,to_number(substr(w_riga,37,7))                              -- numeratore_quota devoluzione
                      ,to_number(substr(w_riga,44,7))                              -- denominatore_quota devoluzione
                      ,substr(w_riga,51,1)                                         -- agevolazione prima casa
                       )
                       ;
            EXCEPTION
             WHEN others THEN
                sql_errm  := substr(SQLERRM,1,100);
                w_errore := 'Errore in inserimento successioni_devoluzioni '||
                            ' ('||sql_errm||')';
                raise errore;
            END;
         else
            null;
         end if;
      else
         if w_tipo_record = 'A' then
            w_num_succ_gia_inserite := w_num_succ_gia_inserite + 1;
         end if;
      end if;
   END LOOP;
   -- Gestione Successioni
   GESTIONE_SUCCESSIONI( a_documento_id, a_utente, a_ctr_denuncia, a_sezione_unica, a_fonte
                       , w_num_succ_gia_inserite, w_num_successioni
                       , w_num_pratiche, w_num_nuovi_oggetti, w_num_nuovi_contribuenti, w_num_nuovi_soggetti
                       , w_pratiche_gia_inserite, a_messaggio);
EXCEPTION
   WHEN ERRORE THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,nvl(w_errore,'vuoto'));
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,substr(SQLERRM,1,200));
end;
/* End Procedure: CARICA_DIC_SUCCESSIONI */
/

