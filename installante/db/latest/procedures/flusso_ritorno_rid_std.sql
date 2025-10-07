--liquibase formatted sql 
--changeset abrandolini:20250326_152423_flusso_ritorno_rid_std stripComments:false runOnChange:true 
 
create or replace procedure FLUSSO_RITORNO_RID_STD
/*************************************************************************
 NOME:        FLUSSO_RITORNO_RID_STD
 DESCRIZIONE: Carica i dati presenti nel flusso di ritorno RID
 NOTE:        ATTENZIONE: LA PROCEDURE E' LA COPIA DELLA VECCHIA
              FLUSSO_RITORNO_RID.
              LA VECCHIA FLUSSO_RITORNO_RID DIVENTA ORA UNA PROCEDURE
              PER LANCIARE FUNZIONI DIFFERENTI A SECONDA DEL CLIENTE.
              AL MOMENTO NON CREDO CHE FUNZIONI PERCHE' LA PARTE DI
              GESTIONE DEL BLOB E' TUTTA COMMENTATA.
 Rev.    Date         Author      Note
 000     21/08/2018   VD          Prima emissione.
*************************************************************************/
  (
       a_documento_id     in      number
     , a_utente           in      varchar2
     , a_messaggio        in out  varchar2
   ) is
w_documento_blob        blob;
--w_documento_clob        clob;
w_number_temp           number;
--dest_offset             number  := 1;
--src_offset              number  := 1;
--amount                  integer := dbms_lob.lobmaxsize;
--blob_csid               number  := dbms_lob.default_csid;
--lang_ctx                integer := dbms_lob.default_lang_ctx;
--warning                 integer;
w_esiti_trattati        number := 0;
w_versamenti_impagati   number := 0;
w_numero_righe          number;
w_riga                  varchar2(122);
w_progressivo10         number;
w_data_valuta           date;
w_causale               varchar2(5) := ' ';
w_importo               number;
w_segno                 varchar2(1);
w_codice_utente         varchar2(16);
w_ni                    number;
w_anno_fattura          number;
--w_numero_fattura        number;
w_tipo_tributo          varchar2(5) := 'TARSU';
w_cod_fiscale           varchar2(16);
w_fattura               number;
w_ruolo                 number;
w_data_pagamento        date;
w_causale_storno        varchar2(2);
w_messaggio             varchar2(2000);
sql_errm                varchar2(200);
errore                  exception;
w_errore                varchar2(200);
BEGIN
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
   --DBMS_OUTPUT.Put_Line(to_char(w_number_temp));
   -- Trasformazione in CLOB
--   begin
--     DBMS_LOB.CREATETEMPORARY(lob_loc=>w_documento_clob, cache=>TRUE, dur=>dbms_lob.SESSION);
--     DBMS_LOB.CONVERTTOCLOB(w_documento_clob,w_documento_blob,amount,dest_offset,src_offset,blob_csid,lang_ctx,warning);
--      exception
--         when others then
--            w_errore := 'Errore in trasformazione Blob in Clob  ('||SQLERRM||')';
--            raise errore;
--   end;
   w_numero_righe := w_number_temp / 122;
   --DBMS_OUTPUT.Put_Line(to_char(w_numero_righe));
   FOR i IN 0 .. w_numero_righe - 1 LOOP
      w_riga := utl_raw.cast_to_varchar2(
                      dbms_lob.substr(w_documento_blob,122, (122 * i ) + 1)
                                        );
      --DBMS_OUTPUT.Put_Line(to_char(i));
      -- Riga '10'
      if substr(w_riga, 2,2) = '10' then
         w_causale        := substr(w_riga, 29,5);
         if w_causale in ('50006','050008','50001','50003','50004','50007','50009','50010') then
            w_progressivo10  := to_number(substr(w_riga, 4,7));
            w_data_valuta    := to_date(substr(w_riga, 23,6),'ddmmyy');
            w_importo        := to_number(substr(w_riga, 34,13)) / 100;
            w_segno          := substr(w_riga, 47,1);
            w_codice_utente  := substr(w_riga, 98,16);
            w_ni             := to_number(substr(w_codice_utente, 7,10));
            --w_anno_fattura   := to_number(substr(w_codice_utente, 10,2));
            --w_numero_fattura := to_number(substr(w_codice_utente, 12,5));
            begin
               select cod_fiscale
                 into w_cod_fiscale
                 from contribuenti
                where ni = w_ni
                    ;
            EXCEPTION
               WHEN others THEN
                  w_errore := ('Errore in recupero codice fiscale, ni:'|| to_char(w_ni) || ' (' || SQLERRM || ')' );
                  raise errore;
            end;
            begin
               select fatt.fattura
                    , ruol.anno_ruolo
                 into w_fattura
                    , w_anno_fattura
                 from fatture  fatt
                    , ruoli    ruol
                    , ( select ogim2.fattura
                             , ogim2.ruolo
                          from oggetti_imposta ogim2
                      group by ogim2.fattura
                             , ogim2.ruolo
                      ) ogim
                where fatt.cod_fiscale   = w_cod_fiscale
                  and ruol.scadenza_prima_rata = w_data_valuta
                  and fatt.importo_totale = w_importo
                  and ruol.ruolo = ogim.ruolo
                  and fatt.fattura = ogim.fattura
                    ;
            EXCEPTION
               WHEN others THEN
                  w_errore := ('Errore in recupero fattura, ni:'|| to_char(w_ni)
                                                        ||' imp: '||to_char(w_importo)
                                                        ||' cf: '||w_cod_fiscale
                                                        ||' data: '||to_char(w_data_valuta,'dd/mm/yyyy')
                                                        || ' (' || SQLERRM || ')' );
                  raise errore;
            end;
         end if;
      end if;
      -- Riga '70'
      if substr(w_riga, 2,2) = '70' then
         if w_causale in ('50010') then
            w_esiti_trattati := w_esiti_trattati + 1;
         elsif w_causale in ('50006','050008','50001','50003','50004','50007','50009') then
            if w_causale = '50007' then
               w_causale_storno := substr(w_riga, 64,2);
            else
               w_causale_storno := '';
            end if;
            begin
              select max(ogim.ruolo)
                into w_ruolo
                from oggetti_imposta ogim
               where ogim.fattura = w_fattura
                 ;
            EXCEPTION
               WHEN others THEN
                  w_errore := ('Errore recupero Ruolo Fattura '|| to_char(w_fattura) || ' (' || SQLERRM || ')' );
                  raise errore;
            end;
            begin
               insert into rid_impagati
                    ( documento_id
                    , fattura
                    , cod_fiscale
                    , anno
                    , tipo_tributo
                    , importo_impagato
                    , causale
                    , causale_storno
                    , ruolo
                    , utente
                    , note
                    , data_variazione)
             values ( a_documento_id
                    , w_fattura
                    , w_cod_fiscale
                    , w_anno_fattura
                    , w_tipo_tributo
                    , w_importo
                    , w_causale
                    , w_causale_storno
                    , w_ruolo
                    , a_utente
                    , ''
                    , trunc(sysdate)
                    )
                  ;
            EXCEPTION
               WHEN others THEN
                  w_errore := ('Errore in inserimento RID_IMPAGATI Fattura '|| to_char(w_fattura) || ' (' || SQLERRM || ')' );
                  raise errore;
            end;
            -- Trattamento versamenti trattati
            w_versamenti_impagati := w_versamenti_impagati + 1;
            w_esiti_trattati := w_esiti_trattati + 1;
         end if;
      end if;
   END LOOP;
   a_messaggio := w_messaggio;
   -- Aggiornamneto Stato
   begin
      update documenti_caricati
         set stato = 2
           , data_variazione = sysdate
           , utente = a_utente
           , note = 'Esiti Trattati: '||to_char(w_esiti_trattati)
                  ||' - Versamenti Impagati: '||to_char(w_versamenti_impagati)
       where documento_id = a_documento_id
           ;
   EXCEPTION
      WHEN others THEN
         sql_errm  := substr(SQLERRM,1,100);
         w_errore := 'Errore in Aggiornamneto Stato del documento '||
                                    ' ('||sql_errm||')';
   end;
   a_messaggio := 'Esiti Trattati: '||to_char(w_esiti_trattati)||chr(13)
                  ||'Versamenti Impagati: '||to_char(w_versamenti_impagati);
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,w_errore||' ('||SQLERRM||')');
END;
/* End Procedure: FLUSSO_RITORNO_RID_STD */
/

