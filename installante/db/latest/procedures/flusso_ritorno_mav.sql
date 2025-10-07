--liquibase formatted sql 
--changeset abrandolini:20250326_152423_flusso_ritorno_mav stripComments:false runOnChange:true 
 
create or replace procedure FLUSSO_RITORNO_MAV
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
w_versamenti_trattati   number := 0;
w_versamenti_inseriti   number := 0;
w_versamenti_non_pagati number := 0;
w_versamenti_gia_presenti number := 0;
w_vers_gia_presente     number;
w_numero_righe          number;
w_riga                  varchar2(122);
w_progressivo14         number;
w_causale               varchar2(5);
w_importo               number;
w_segno                 varchar2(1);
w_codice_utente         varchar2(16);
w_ni14                  number;
w_anno_fattura          number;
w_numero_fattura        number;
w_progressivo51         number;
w_ni51                  number;
w_data_pagamento        date;
w_tipo_tributo          varchar2(5) := 'TARSU';
w_cod_fiscale           varchar2(16);
w_fattura               number;
w_ruolo                 number;
w_messaggio             varchar2(2000);
sql_errm                varchar2(200);
errore                  exception;
w_errore                varchar2(200);
BEGIN
   -- Cambio stato in caricamento in corso per gestione Web
   update documenti_caricati
           set stato = 15
             , data_variazione = sysdate
             , utente = a_utente
         where documento_id = a_documento_id
             ;
   commit;
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
      if substr(w_riga, 2,2) = '14' then
         w_progressivo14  := to_number(substr(w_riga, 4,7));
         w_causale        := substr(w_riga, 29,5);
         w_importo        := to_number(substr(w_riga, 34,13)) / 100;
         w_segno          := substr(w_riga, 47,1);
         w_codice_utente  := substr(w_riga, 98,16);
         w_ni14           := to_number(substr(w_codice_utente, 4,6));
         w_anno_fattura   := to_number('20'||substr(w_codice_utente, 10,2));
         w_numero_fattura := to_number(substr(w_codice_utente, 12,5));
      end if;
      if substr(w_riga, 2,2) = '51' then
         w_progressivo51  := to_number(substr(w_riga, 4,7));
         w_ni51           := to_number(substr(w_riga,11,10));
         w_data_pagamento := to_date(substr(w_riga,110,6),'ddmmyy');
         if w_progressivo51 = w_progressivo14 then
            w_versamenti_trattati := w_versamenti_trattati + 1;
            if w_causale in ('07000','07011') then
               begin
                  select cod_fiscale
                    into w_cod_fiscale
                    from contribuenti
                   where ni = w_ni14
                       ;
               EXCEPTION
                  WHEN others THEN
                     w_errore := ('Errore in recupero codice fiscale, ni:'|| to_char(w_ni14) || ' (' || SQLERRM || ')' );
                     raise errore;
               end;
               begin
                  select fattura
                    into w_fattura
                    from fatture
                   where anno   = w_anno_fattura
                     and numero = w_numero_fattura
                       ;
               EXCEPTION
                  WHEN others THEN
                     w_errore := ('Errore in recupero fattura, ni:'|| to_char(w_ni14)
                     ||' N.Fatt: '|| to_char(w_numero_fattura)
                     ||' Anno Fatt: '|| to_char(w_anno_fattura)
                     || ' (' || SQLERRM || ')' );
                     raise errore;
               end;
               -- recupero Ruolo
               begin
                  select ogim.ruolo
                    into w_ruolo
                    from oggetti_imposta ogim
                   where ogim.fattura = w_fattura
                group by ogim.ruolo
                       ;
               EXCEPTION
                  when no_data_found then
                     w_errore := ('Errore in recupero ruolo cf:'|| w_cod_fiscale || ' (' || SQLERRM || ')' );
                     raise errore;
                  WHEN others THEN
                     w_errore := ('Errore in recupero ruolo cf:'|| w_cod_fiscale || ' (' || SQLERRM || ')' );
                     raise errore;
               end;
               -- Verifica presenza versamento
               w_vers_gia_presente := 0;
               begin
                  select count(1)
                    into w_vers_gia_presente
                    from versamenti
                   where anno         = w_anno_fattura
                     and cod_fiscale  = w_cod_fiscale
                     and tipo_tributo = w_tipo_tributo
                     and importo_versato = w_importo
                     and data_pagamento  = w_data_pagamento
                     and ruolo           = w_ruolo
                       ;
               EXCEPTION
                  when no_data_found then
                     w_vers_gia_presente := 0;
                  WHEN others THEN
                     w_errore := ('Errore in verifica versamenti cf:'|| w_cod_fiscale || ' (' || SQLERRM || ')' );
                     raise errore;
               end;
               if w_vers_gia_presente = 0 then
                  begin
                     insert into versamenti
                          ( cod_fiscale
                          , anno
                          , tipo_tributo
                          --, oggetto_imposta
                          --, rata_imposta
                          , rata
                          , data_pagamento
                          , importo_versato
                          , fattura
                          , ruolo
                          , fonte
                          , utente
                          , note)
                   values ( w_cod_fiscale
                          , w_anno_fattura
                          , w_tipo_tributo
                        --  , oggetto_imposta
                        --  , rata_imposta
                          , 1
                          , w_data_pagamento
                          , w_importo
                          , w_fattura
                          , w_ruolo
                          , 20
                          , a_utente
                          , ''
                          )
                        ;
                  EXCEPTION
                     WHEN others THEN
                        w_errore := ('Errore in inserimento delega di '|| w_cod_fiscale || ' (' || SQLERRM || ')' );
                        raise errore;
                  end;
                  w_versamenti_inseriti := w_versamenti_inseriti + 1;
               else
                  w_versamenti_gia_presenti := w_versamenti_gia_presenti + 1;
               end if;
            elsif w_causale in ('07006','07008','07010') then
               -- Trattamento versamenti non pagati
               w_versamenti_non_pagati := w_versamenti_non_pagati + 1;
            end if;
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
           , note = 'Versamenti Trattati: '||to_char(w_versamenti_trattati)
                  ||' - Versamenti Inseriti: '||to_char(w_versamenti_inseriti)
                  ||' - Versamenti Gia Presenti: '||to_char(w_versamenti_gia_presenti)
                  ||' - Versamenti Non Pagati: '||to_char(w_versamenti_non_pagati)
       where documento_id = a_documento_id
           ;
   EXCEPTION
      WHEN others THEN
         sql_errm  := substr(SQLERRM,1,100);
         w_errore := 'Errore in Aggiornamneto Stato del documento '||
                                    ' ('||sql_errm||')';
   end;
   a_messaggio := 'Versamenti Trattati: '||to_char(w_versamenti_trattati)||chr(13)
                  ||'Versamenti Inseriti: '||to_char(w_versamenti_inseriti)||chr(13)
                  ||'Versamenti Gia Presenti: '||to_char(w_versamenti_gia_presenti)||chr(13)
                  ||'Versamenti Non Pagati: '||to_char(w_versamenti_non_pagati);
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,w_errore||' ('||SQLERRM||')');
END;
/* End Procedure: FLUSSO_RITORNO_MAV */
/

