--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_anagrafe_esterna stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     CARICA_ANAGRAFE_ESTERNA
( a_documento_id     in     number
, a_utente           in     varchar2
, a_messaggio        in out varchar2
)
IS
/*****************************************************************************************
 Versione  Data        Autore    Descrizione
 2         11/03/2024  AB        fatta la substr(10) di esponente e interno
 1         19/05/2023  AB        Trovati valori strani e fatta la replace di #N/D con null
 0         06/02/2023  AB        Prima emissione,
                                 nasce per la LAC di Castelfiorentino
******************************************************************************************/
  w_titolo_documento          number;
  w_documento_blob            blob;
  w_documento_clob            clob;
  dest_offset                 number := 1;
  src_offset                  number := 1;
  amount                      integer := DBMS_LOB.lobmaxsize;
  blob_csid                   number  := DBMS_LOB.default_csid;
  lang_ctx                    integer := DBMS_LOB.default_lang_ctx;
  warning                     integer;

  w_stato                     number;
  w_dimensione_file           number;
  w_contarighe                number := 0;
  w_posizione                 number;
  w_posizione_old             number;
  w_step                      number(2);

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

  rec_lac                 anamin_lac%rowtype;

  w_errore                varchar(2000) := NULL;
  errore                  exception;
  sql_errm                varchar2(100);

BEGIN
   -- Cambio stato in caricamento in corso per gestione Web
update documenti_caricati
set stato = 15
  , data_variazione = sysdate
  , utente = a_utente
where documento_id = a_documento_id
;
commit;

begin
select titolo_documento, contenuto, stato
into w_titolo_documento, w_documento_blob, w_stato
from documenti_caricati doca
where doca.documento_id = a_documento_id
;
EXCEPTION
      when others then
         raise_application_error
             (-20999,'Errore in ricerca DOCUMENTI_CARICATI '||
                     '('||SQLERRM||')');
end;

   if w_stato in (1,15) then
     -- Verifica dimensione file caricato
     w_dimensione_file:= DBMS_LOB.GETLENGTH(w_documento_blob);
--dbms_output.put_line('dentro in (1,15) - dim file '||w_dimensione_file );
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
     w_contarighe          := 0;
     w_posizione_old       := 218;
     w_posizione           := 218;
     --
     a_messaggio := 'Caricate '|| to_char(w_righe_caricate) ||' righe di anagrafiche.';
end if;

   IF w_titolo_documento = 35 then -- LAC
begin
        delete anamin_lac
        ;
exception
       when others then
         w_errore :=
           'Errore in Eliminazione ANAMIN_LAC (' || sqlerrm || ')';
         raise errore;
end;

--dbms_output.put_line('dentro = 35 - dim file '||w_dimensione_file );
     while w_posizione < w_dimensione_file
     loop
       w_errore := null;
       w_posizione     := instr (w_documento_clob, chr (10), w_posizione_old);
       w_riga          := substr (w_documento_clob, w_posizione_old, w_posizione-w_posizione_old+1);
       w_posizione_old := w_posizione + 1;

       -- Determinazione numero di separatori presenti nella riga
       w_num_separatori := length(w_riga) - length(replace(w_riga,w_separatore,''));
       w_lunghezza_riga := length(w_riga);
       w_inizio     := 1;
       w_occorrenza := 1;
       rec_lac      := null;
begin
         while w_occorrenza <= w_num_separatori
         loop
           w_fine := instr(w_riga,w_separatore,w_inizio,1);
           w_campo := rtrim(substr(w_riga,w_inizio,w_fine - w_inizio));
           w_campo := replace(w_campo,'#N/D','');  -- AB 19/05/2023 c'era questo valore in un codice via a Castelfiorentino
           if w_occorrenza = 1 then
              rec_lac.codpro := to_number(w_campo);
           elsif
w_occorrenza = 2 then
              rec_lac.codcom := to_number(w_campo);
           elsif
w_occorrenza = 3 then
              rec_lac.tipores := to_number(w_campo);
           elsif
w_occorrenza = 4 then
              rec_lac.codicefam := to_number(w_campo);
           elsif
w_occorrenza = 5 then
              rec_lac.codiceconv := to_number(w_campo);
           elsif
w_occorrenza = 6 then
              rec_lac.idindividuo := to_number(w_campo);
           elsif
w_occorrenza = 7 then
              rec_lac.cognome := w_campo;
           elsif
w_occorrenza = 8 then
              rec_lac.nome := w_campo;
           elsif
w_occorrenza = 9 then
              rec_lac.codfiscale := w_campo;
           elsif
w_occorrenza = 10 then
              rec_lac.sesso := to_number(w_campo);
           elsif
w_occorrenza = 11 then
              rec_lac.datanas := w_campo;
           elsif
w_occorrenza = 12 then
              rec_lac.pronas := w_campo;
           elsif
w_occorrenza = 13 then
              rec_lac.comnas := to_number(w_campo);
           elsif
w_occorrenza = 14 then
              rec_lac.estnas := to_number(w_campo);
           elsif
w_occorrenza = 15 then
              rec_lac.cittad := to_number(w_campo);
           elsif
w_occorrenza = 16 then
              rec_lac.ncomp := to_number(w_campo);
           elsif
w_occorrenza = 17 then
              rec_lac.relpar := to_number(w_campo);
           elsif
w_occorrenza = 18 then
              rec_lac.staciv := to_number(w_campo);
           elsif
w_occorrenza = 19 then
              rec_lac.dataiscr := w_campo;
           elsif
w_occorrenza = 20 then
              rec_lac.idtoponimo := to_number(w_campo);
           elsif
w_occorrenza = 21 then
              rec_lac.specie := w_campo;
           elsif
w_occorrenza = 22 then
              rec_lac.denominazione := w_campo;
           elsif
w_occorrenza = 23 then
              rec_lac.civico := to_number(w_campo);
           elsif
w_occorrenza = 24 then
              rec_lac.esponente := substr(w_campo,1,10);
           elsif
w_occorrenza = 25 then
              rec_lac.interno := substr(replace(w_campo,'Int.',''),1,10);
           elsif
w_occorrenza = 26 then
              rec_lac.cap := w_campo;
           elsif
w_occorrenza = 27 then
              rec_lac.nsez := to_number(w_campo);
           elsif
w_occorrenza = 28 then
              rec_lac.filler := w_campo;
end if;
           w_occorrenza := w_occorrenza + 1;
           w_inizio := instr(w_riga,w_separatore,w_inizio,1) + 1;
end loop;
exception
          when others then
            w_errore := substr('Riga : '||w_riga||' - '||sqlerrm,1,2000);
            raise errore;
end;

       if w_errore is null then
          if rec_lac.idindividuo is not null then
             --
             -- Controllo esistenza record
             --
begin
select 'Dati gia'' inseriti'
into w_errore
from anamin_lac
where idindividuo = rec_lac.idindividuo;
exception
               when no_data_found then
                 w_errore := null;
when too_many_rows then
                 w_errore := 'Dati gia'' inseriti';
end;
             if w_errore is null then
begin
insert into anamin_lac
values rec_lac;
exception
                  when others then
                    w_errore := substr('Ins. ANAMIN_LAC (IdIndividuo: '
                             ||rec_lac.idindividuo
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
       , rec_lac.cognome
       , rec_lac.nome
       , rec_lac.codfiscale
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

     aggana;  -- esecuzione di aggana per aggiornare le anagrafiche dopo aver riempito la tabella anamin_lac di passaggio

     -- Aggiornamento Stato
begin
update documenti_caricati
set stato = 2
  , data_variazione = sysdate
  , utente = a_utente
  , note = 'Anagrafiche: righe caricate '|| to_char(w_righe_caricate) ||', righe scartate: '||to_char(w_conta_anomalie)
where documento_id = a_documento_id
;
EXCEPTION
        WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           w_errore := 'Errore in Aggiornamento Stato del documento '||
                                      ' ('||sql_errm||')';
end;
     a_messaggio := 'Caricate '|| to_char(w_righe_caricate) ||' righe di Anagrafiche.';
end if;
dbms_output.put_line(a_messaggio);

EXCEPTION
   WHEN ERRORE THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,nvl(w_errore,'vuoto'));
WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' - '||substr(SQLERRM,1,100));
END;
/* End Procedure: CARICA_ANAGRAFE_ESTERNA */
/
