--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_versamenti_titr_f24 stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     CARICA_VERSAMENTI_TITR_F24
/*************************************************************************
 NOME:        CARICA_VERSAMENTI_TITR_F24
 DESCRIZIONE: Carica i dati di un file di versamenti effettuati mediante
              F24 nella tabella WRK_TRAS_ANCI.
 NOTE:
 Rev.    Date         Author      Note
 012     26/09/2024   AB          Spostato l'aggiornamento di documenti_caricati
                                  dopo l'ultima elaborazione di Forniture_AE
 011     16/03/2023   VM          #55165 - Cambiata chiamata alle subprocedures
 010     15/03/2023   DM          #60197 - Modificata stringa individuazione ruolo coattivo
 009     15/03/2023   VM          #60197 - Il messaggio restituito contiene:
                                  riepilogo dell'elaborazione, il separatore <FINE_RIEPILOGO>
                                  e log con errori sul documento.
 008     22/09/2021   VD          Si ricarica il file per acquisire i dati per la
                                  contabilita finanziaria
 007     26/02/2019   DM          Aggiunto cambio stato in
                                  'elaborazione in corso'
 006     31/05/2018   VD          Aggiunta gestione TOSAP/ICP
 005     05/07/2016   VD          Suddivisa gestione revoche e/o ripristini
                                  per tipo tributo e spostato lancio
                                  procedure nelle varie procedure per tipo
                                  tributo
 004     14/06/2016   VD          Aggiunta gestione tipo record G9 -
                                  Revoca o ripristino delega
 003     16/01/15     VD          Aggiunta gestione documento_id su
                                  VERSAMENTI e WRK_VERSAMENTI
 002     24/11/14     Betta T.    Tolto commit per evitare flag di caricato su
                                  file con errori
 001     14/10/14     Betta T.    Cambiato il test su tipo imposta per modifiche
                                  al tracciato del ministero
 000     21/10/2013   --          Prima emissione
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
w_stato                 number;
w_number_temp           number;
w_numero_righe          number;
w_riga                  varchar2(2000);
w_lunghezza_riga        number := 302;
w_righe_caricate        number := 0;
w_errore                varchar(2000) := NULL;
errore                  exception;
sql_errm                varchar2(100);
w_fonte                 versamenti.fonte%type := 2;
w_int_cfa               varchar2(1);
w_riepilogo             varchar(2000) := NULL;
w_log_documento         varchar(2000) := NULL;
begin
   if w_commenti > 0 then
      DBMS_OUTPUT.Put_Line('---- Inizio ----');
   end if;
   -- Estrazione BLOB
   begin
      select contenuto,stato
        into w_documento_blob,w_stato
        from documenti_caricati doca
       where doca.documento_id  = a_documento_id
           ;
   end;
   if w_stato = 1 THEN
      -- Cambio stato: elaborazione in corso
      update documenti_caricati
           set stato = 15
             , data_variazione = sysdate
             , utente = a_utente
         where documento_id = a_documento_id
             ;
      -- Necessaria per far vedere il nuovo stato alla TributiWeb
      commit;
     -- Verifica dimensione file caricato
     w_number_temp:= DBMS_LOB.GETLENGTH(w_documento_blob);
     if w_commenti > 0 then
        DBMS_OUTPUT.Put_Line('Number temp: '||w_number_temp);
     end if;
     if nvl(w_number_temp,0) = 0 then
       w_errore := 'Attenzione File caricato Vuoto - Verificare Client Oracle';
       raise errore;
     end if;
     w_numero_righe := w_number_temp / w_lunghezza_riga;
     if w_commenti > 0 then
        DBMS_OUTPUT.Put_Line(to_char(w_numero_righe));
     end if;
     FOR i IN 0 .. w_numero_righe - 1 LOOP
        w_riga := utl_raw.cast_to_varchar2(
                        dbms_lob.substr(w_documento_blob,w_lunghezza_riga, (w_lunghezza_riga * i ) + 1)
                                          );
        if w_commenti > 0 then
           DBMS_OUTPUT.Put_Line(to_char(i));
        end if;
        --
        -- (14/06/2016 - VD) - Aggiunta gestione tipo record G9
        --
        if (substr(w_riga,1,2) = 'G1' and substr(w_riga,260,1) in ('I','U','A','T','O','C')) or     -- versamenti ICI/TASI/TARSU/COSAP/ICP
           (substr(w_riga,1,2) = 'G9' and substr(w_riga,145,1) in ('I','U','A','T','O','C')) then   -- revoca versamenti ICI/TASI/TARSU/COSAP/ICP
           BEGIN
             w_righe_caricate := w_righe_caricate + 1;
             insert into wrk_tras_anci
                    ( anno
                    , progressivo
                    , dati
                    )
             values ( 2
                    , w_righe_caricate
                    , w_riga
                    )
             ;
           EXCEPTION
             WHEN others THEN
               w_errore := 'Errore in inserimento riga n.'||w_righe_caricate||
                           ' cf '||rtrim(substr(w_riga,50,16))||
                           ' ('||sqlerrm||')';
               RAISE errore;
           END;
        end if;
     END LOOP;
     w_riepilogo := 'Caricate '|| to_char(w_righe_caricate) ||' righe di versamenti.';
   end if;
--
   CARICA_VERSAMENTI_ICI_F24 (a_documento_id, '%', w_log_documento);
   CARICA_VERSAMENTI_TARES_F24 (a_documento_id, '%', w_log_documento);
   CARICA_VERSAMENTI_TASI_F24 (a_documento_id, '%', w_log_documento);
--
-- (VD - 31/05/2018): aggiunto trattamento tributi minori (COSAP/ICP)
--
   CARICA_VERSAMENTI_TRMI_F24 (a_documento_id, '%', w_log_documento);
--
-- (VD - 05/07/2016): il trattamento degli annullamenti e' stato suddiviso
--                    per tipo tributo e spostato nelle relative procedure
--
--   CARICA_ANNULLAMENTI_F24 (a_documento_id);
--
-- 25/10/2013 AB non eliminiamo nulla perchè potrebbero sparire record che invece servono,
-- lascio cmq indicato cosa si era modificato in precedenza
-- eliminiamo da wrk_tras_anci le righe che non sono passate in wrk_versamenti
-- nel file potremmo avere dati che noi non siamo in grado di trattare.
--   delete wrk_tras_anci wkta
--    where wkta.anno                = 2
--   ;

--
-- (VD - 22/09/2021): si ricarica il file per acquisire i dati per la
--                    contabilita finanziaria
   w_int_cfa := f_inpa_valore('CFA_INT');
   if nvl(w_int_cfa,'N') = 'S' then
      delete wrk_tras_anci wkta
       where wkta.anno = 2;
      w_number_temp:= DBMS_LOB.GETLENGTH(w_documento_blob);
      if w_commenti > 0 then
         DBMS_OUTPUT.Put_Line('Number temp: '||w_number_temp);
      end if;
      if nvl(w_number_temp,0) = 0 then
        w_errore := 'Attenzione File caricato Vuoto - Verificare Client Oracle';
        raise errore;
      end if;
      w_numero_righe := w_number_temp / w_lunghezza_riga;
      if w_commenti > 0 then
         DBMS_OUTPUT.Put_Line(to_char(w_numero_righe));
      end if;
      FOR i IN 0 .. w_numero_righe - 1 LOOP
         w_riga := utl_raw.cast_to_varchar2(
                         dbms_lob.substr(w_documento_blob,w_lunghezza_riga, (w_lunghezza_riga * i ) + 1)
                                           );
         if w_commenti > 0 then
            DBMS_OUTPUT.Put_Line(to_char(i));
         end if;
         if substr(w_riga,1,2) not in ('A1','Z1') then
            BEGIN
              w_righe_caricate := w_righe_caricate + 1;
              insert into wrk_tras_anci
                     ( anno
                     , progressivo
                     , dati
                     )
              values ( 2
                     , w_righe_caricate
                     , w_riga
                     )
              ;
            EXCEPTION
              WHEN others THEN
                w_errore := 'Errore in inserimento riga n.'||w_righe_caricate||
                            ' tipo record: '||substr(w_riga,1,2)||
                            ' ('||sqlerrm||')';
                RAISE errore;
            END;
         end if;
      END LOOP;
   end if;
   --commit;
   ELABORAZIONE_FORNITURE_AE.ELABORA(a_documento_id,w_errore);
--
-- spostato alla fine di tutto AB 26/09/2024
--
   a_messaggio := w_riepilogo || '<FINE_RIEPILOGO>' || w_log_documento;
   if instr(w_log_documento, 'inserito versamento su pratica già andata a ruolo') > 0 then
     w_log_documento := 'Presenti versamenti per pratiche con ruolo emesso.';
   end if;
   -- Aggiornamento Stato
   begin
      update documenti_caricati
         set stato = 2
           , data_variazione = sysdate
           , utente = a_utente
           , note = w_riepilogo || CASE WHEN w_log_documento IS NULL THEN '' ELSE (chr(13)||chr(10)|| w_log_documento) END
       where documento_id = a_documento_id
           ;
   EXCEPTION
      WHEN others THEN
         sql_errm  := substr(SQLERRM,1,100);
         w_errore := 'Errore in Aggiornamento Stato del documento '||
                                    ' ('||sql_errm||')';
   end;
EXCEPTION
   WHEN ERRORE THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,nvl(w_errore,'vuoto'));
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' - '||substr(SQLERRM,1,100));
end;
/* End Procedure: CARICA_VERSAMENTI_TITR_F24 */
/
