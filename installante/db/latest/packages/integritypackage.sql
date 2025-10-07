--liquibase formatted sql 
--changeset abrandolini:20250326_152429_integritypackage stripComments:false runOnChange:true 
 
create or replace package integritypackage
/******************************************************************************
 NOME:        IntegrityPackage
 DESCRIZIONE: Oggetti per la gestione della Integrita Referenziale.
              Contiene le Procedure e function per la gestione del livello di
              annidamento dei trigger.
              Contiene le Procedure per il POSTING degli script alla fase di
              AFTER STATEMENT.
 REVISIONI:
 Rev. Data        Autore  Descrizione
 ---- ----------  ------  ----------------------------------------------------
 01    23/01/2001  MF      Inserimento commento.
 02    04/12/2002  SN      In caso di errore visualizza lo statement
 03    22/12/2003  SN      Rilevamento errore in caso di select
                          Sistemazione frase in base a default stabiliti.
 04    10/05/2004  SN      Se errore 20999 non si visualizza lo statement a
                          meno che non sia stata settata la variabile debug a 1.
 05    20/12/2004  SN      Se errore non compreso fra 20000 e 20999 non visualizza
                          lo statement a meno che debug sia = 1.
 06    04/08/2005  SN      Gestione di integrityerror.
 07    26/08/2005  SN      Sistemazione messaggio di errore
 08    12/10/2005  SN      Errore rimappato attraverso si4.get_error
 09    21/10/2005  SN      Modificato controllo errore
 10    30/08/2006  FT      Modifica dichiarazione subtype per incompatibilità con
                           versione 7 di Oracle
 11    04/12/2008  MM      Creazione procedure log.
 12    20/03/2009  MM      Creazione procedure log con parametro clob.
 NOTA: In futuro verra tolta la substr nella SISTEMA MESSAGGIO quando verra
 rilasciata una versione di ad4 che lo consenta.
******************************************************************************/
as
   d_revision varchar2(30);
   subtype t_revision is d_revision%type;
   s_revisione      t_revision     := 'V1.12';
   function versione
      return t_revision;
   -- Variabili per SET Switched FUNCTIONAL Integrity
   functional       boolean        := true;
   integrityerror   exception;
   procedure setdebugon;
   procedure setdebugoff;
   -- Procedure for Referential Integrity
   procedure setfunctional;
   procedure resetfunctional;
   procedure initnestlevel;
   function getnestlevel
      return number;
   procedure nextnestlevel;
   procedure previousnestlevel;
   /* Variabili e Procedure per IR su Relazioni Ricorsive */
   type t_operazione is table of varchar2 (32000)
      index by binary_integer;
   type t_messaggio is table of varchar2 (2000)
      index by binary_integer;
   d_istruzione     t_operazione;
   d_messaggio      t_messaggio;
   d_entry          binary_integer := 0;
   procedure set_postevent (p_istruzione in varchar2, p_messaggio in varchar2);
   procedure exec_postevent;
/******************************************************************************
 DESCRIZIONE: Esegue gli statement precedentemente impostati.
              Se inizia con:
              SELECT: toglie eventuale ';' in fondo
              :=    : si suppone segua la chiamata ad una funzione, viene
                      dichiarata una variabile e le si assegna il ritorno
              in caso di stringa diversa mette il codice fra begin e end
 ******************************************************************************/
   procedure log(p_log in varchar2);
   procedure log(p_log in clob);
end integritypackage;
/* End Package: IntegrityPackage
   N.B.: In caso di "Generate Trigger" successive alla prima
         IGNORARE Errore di Package gia presente
*/
/

create or replace package body integritypackage
/******************************************************************************
 NOME:        IntegrityPackage
 DESCRIZIONE: Oggetti per la gestione della Integrita Referenziale.
              Contiene le Procedure e function per la gestione del livello di
              annidamento dei trigger.
              Contiene le Procedure per il POSTING degli script alla fase di
              AFTER STATEMENT.
 REVISIONI:
 Rev. Data        Autore  Descrizione
 ---- ----------  ------  ----------------------------------------------------
 1    23/01/2001  MF      Inserimento commento.
 2    04/12/2002  SN      In caso di errore visualizza lo statement
 3    22/12/2003  SN      Rilevamento errore in caso di select
                          Sistemazione frase in base a default stabiliti.
 4    10/05/2004  SN      Se errore 20999 non si visualizza lo statement a
                          meno che non sia stata settata la variabile debug a 1.
 5    20/12/2004  SN      Se errore non compreso fra 20000 e 20999 non visualizza
                          lo statement a meno che debug sia = 1.
 6    04/08/2005  SN      Gestione di integrityerror.
 7    26/08/2005  SN      Sistemazione messaggio di errore
 8    12/10/2005  SN      Errore rimappato attraverso si4.get_error
 9    21/10/2005  SN      Modificato controllo errore
 10   07/03/2006  SN      Controllo dinamico si4_get error e sistemata versione
 11   30/08/2006  FT      Modifica dichiarazione subtype per incompatibilità con
                          versione 7 di Oracle
 12   14/09/2006  FT      In exec_postevent: inserita inizializzazione del nestlevel
                          anche in caso di exception; corretta memorizzazione numero di
                          righe processate
 13   29/11/2006  FT      Modificata inizializzazione (a 0) del flag debug
 14   04/12/2008  MM      Creazione procedure log.
 15   04/12/2008  MM      Creazione procedure log con parametro clob.
 16   13/05/2009  MM      Modificata procedure log con parametro clob.
 17   19/05/2009  MM      Modificata procedure log con parametro clob per incompatibilita
                          con oracle 8.
 NOTA: In futuro verra tolta la substr nella SISTEMA MESSAGGIO quando verra
 rilasciata una versione di ad4 che lo consenta.
******************************************************************************/
as
   nestlevel          pls_integer;
   -- Variabile da valorizzare a 1 per visualizzare l'istruzione
   -- che genera errore in ExecPostEvent anche se con errore user defined (20999)
   debug              pls_integer := 0;
   d_lungo varchar2 (32767);
   subtype t_lungo is d_lungo%type;
   s_revisione_body   t_revision  := '017';
   function versione
      return t_revision
   is
   /******************************************************************************
    NOME:        VERSIONE
    DESCRIZIONE: Restituisce versione e revisione di distribuzione del package.
    RITORNA:     stringa VARCHAR2 contenente versione e revisione.
    NOTE:        Primo numero  : versione compatibilita del Package.
                 Secondo numero: revisione del Package specification.
                 Terzo numero  : revisione del Package body.
   ******************************************************************************/
   begin
      return s_revisione || '.' || s_revisione_body;
   end versione;
   procedure setdebugon
   is
   begin
      debug := 1;
   end;
   procedure setdebugoff
   is
   begin
      debug := 0;
   end;
   procedure sistema_messaggio_errore (
      p_errore        in       varchar2,
      p_actual_istr   in       varchar2,
      p_messaggio     out      varchar2,
      p_codice        out      varchar2
   )
 /***********************************************************************************
 NOME:        sistema_messaggio_errore
 DESCRIZIONE: Esecuzione istruzioni memorizzate in POST Statement.
 ARGOMENTI:   p_errore     : errore rilevato in esecuzione dello statement
              p_actual_istr: istruzione che ha generato l'errore
              p_messaggio  : messaggio di errore da visualizzare
              p_codice     :    numero di errore da visualizzare
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------------
 10   07/03/2006  SN    In caso di errore decide quale numero di errore visualizzare
                        e quale messaggio.
                        Se l'errore e user-defined quindi tra -20000 e -20999  si
                        comporta in modo diverso a seconda che sia attivo o meno
                        il debug:
                        1)debug attivo: visualizza statement che ha causato l'errore.
                        2)debug inattivo: visualizza solo il messaggio di errore
                        Se l'errore intercettato e generato direttamente da Oracle
                        si pensa che fosse non voluto e viene sempre visualizzato
                        lo statement che lo ha generato indipendentemente da come
                        il debug e settato.
                        Se durante l'errore viene scatenato un integrity error lo
                        statement non viene mai visualizzato indipendentemente da
                        come il debug e settato.
************************************************************************************/
   is
      d_errore                t_lungo := p_errore;
      d_ultima_parte_errore   t_lungo;
      d_err_user_defined      boolean := false;
   begin
   d_errore := replace (d_errore, 'ORA-', 'ora-');
      if substr (d_errore, instr (d_errore, 'ora-') + 4, 2) = '20'
      then
         d_err_user_defined := true;
         -- se user defined ributto fuori lo stesso numero di errore
         p_codice := substr (d_errore, instr (d_errore, 'ora') + 3, 6);
      end if;
      declare
         cursor c_esiste_pac
         is
            select 1 esiste
              from all_arguments
             where package_name = 'SI4'
               and owner = user
               and position = 1
               and object_name = 'GET_ERROR';
         d_esiste_pac   c_esiste_pac%rowtype;
      begin
         open c_esiste_pac;
         fetch c_esiste_pac
          into d_esiste_pac;
         if c_esiste_pac%found and d_esiste_pac.esiste = 1
         then
            -- sistema d_errore ricaricandolo con sql dinamico
            declare
               cursor_name      integer;
               rows_processed   integer;
               d_ritorno        t_lungo;
            begin
               cursor_name := DBMS_SQL.open_cursor;
               DBMS_SQL.parse (cursor_name,
                                  'select si4.get_error('''
                               || replace (p_errore, '''', '''''')
                               || ''') from dual',
                               DBMS_SQL.native
                              );
               DBMS_SQL.define_column (cursor_name, 1, d_ritorno, 32000);
               rows_processed := DBMS_SQL.execute (cursor_name);
               --esecuzione istruzione e controllo errore
               if DBMS_SQL.fetch_rows (cursor_name) > 0
               then
                  DBMS_SQL.column_value (cursor_name, 1, d_ritorno);
                  d_errore := d_ritorno;
               -- dinamico = si4.get_error(p_errore);
               end if;
               DBMS_SQL.close_cursor (cursor_name);
            exception
               when others
               then
                  DBMS_SQL.close_cursor (cursor_name);
                  raise;
            end;
         end if;
         close c_esiste_pac;
      end;
      d_errore := replace (d_errore, 'ORA-', 'ora-');
      initnestlevel;
      p_messaggio := null;
      -- se user defined visualizzo l'istruzione solo se debug = 1
      -- altrimenti sempre visualizzata istruzione
      if d_err_user_defined
      then         -- se user defined ributto fuori lo stesso numero di errore
         if instr (d_errore, 'ora') = 1 -- inizia con codice errore
         then
         d_errore := substr (d_errore, 11);
         end if;
         if instr (d_errore, 'ora-') > 0
         then
            d_ultima_parte_errore :=
                                  substr (d_errore, instr (d_errore, 'ora-'));
            d_errore :=
               rtrim (substr (d_errore, 1, instr (d_errore, 'ora-') - 1),
                      chr (10)
                     );
         end if;
      else                                                 -- non user defined
         p_codice := -20999;
      end if;
      p_messaggio := d_errore || chr (10);
      if not d_err_user_defined or debug = 1
      then   -- se non user defined o debug attivo visualizzo anche istruzione
         p_messaggio := p_messaggio || 'ISTRUZIONE :' || p_actual_istr;
      end if;
      p_messaggio := p_messaggio || chr (10) || d_ultima_parte_errore;
      -- vincolo in powerbuilder messaggio minore di 200 caratteri
      p_messaggio := substr (p_messaggio, 1, 200) || '...';
   end sistema_messaggio_errore;
-- Procedure to Initialize Switched Functional Integrity
   procedure setfunctional
   is
   begin
      functional := true;
   end;
-- Procedure to Reset Switched Functional Integrity
   procedure resetfunctional
   is
   begin
      functional := false;
   end;
-- Procedure to initialize the trigger nest level
   procedure initnestlevel
   is
   begin
      nestlevel := 0;
      d_entry := 0;
   end;
-- Function to return the trigger nest level
   function getnestlevel
      return number
   is
   begin
      if nestlevel is null
      then
         nestlevel := 0;
      end if;
      return (nestlevel);
   end;
-- Procedure to increase the trigger nest level
   procedure nextnestlevel
   is
   begin
      if nestlevel is null
      then
         nestlevel := 0;
      end if;
      nestlevel := nestlevel + 1;
   end;
-- Procedure to decrease the trigger nest level
   procedure previousnestlevel
   is
   begin
      nestlevel := nestlevel - 1;
   end;
-- Procedure Memorizzazione istruzioni da attivare in POST statement
   procedure set_postevent
/******************************************************************************
 NOME:        Set_PostEvent
 DESCRIZIONE: Memorizzazione istruzioni da attivare in POST statement.
 ARGOMENTI:   a_istruzione VARCHAR2 Istruzione SQL da memorizzare.
              a_messaggio  VARCHAR2 Messaggio da inviare per errore in esecuzione.
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 1    23/01/2001  MF    Inserimento commento.
******************************************************************************/
   (p_istruzione in varchar2, p_messaggio in varchar2)
   is
      actual_level   pls_integer;
   begin
      actual_level := integritypackage.getnestlevel;
      d_entry := d_entry + 1;
      d_istruzione (d_entry) := p_istruzione;
      d_messaggio (d_entry) := lpad (actual_level, 2, '0') || p_messaggio;
   end set_postevent;
-- Procedure Esecuzione istruzioni memorizzate in POST Statement
   procedure exec_postevent
/***********************************************************************************
 NOME:        Exec_PostEvent
 DESCRIZIONE: Esecuzione istruzioni memorizzate in POST Statement.
 ARGOMENTI:   -
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------------
 1    23/01/2001  MF    Inserimento commento.
 2    04/12/2002  SN    In caso di errore visualizza lo statement
 3    22/12/2003  SN    Rilevamento errore in caso di select
                        Sistemazione frase in base a default stabiliti.
 4    10/05/2004  SN    Modificato ExecPostEvent per gestione errore 20999
                        e visualizzazione statement solo se variabile debug a 1.
                        Usati solo 200 caratteri per messaggio di errore altrimenti
                        problemi durante la visualizzazione in PB (x lo standard).
 10   31/10/2005  SN    Tolta substr del messaggio di errore a 200 caratteri.
 12   14/09/2006  FT    In exec_postevent: inserita inizializzazione del nestlevel
                        anche in caso di exception; corretta memorizzazione numero di
                        righe processate
************************************************************************************/
   is
      cursor_id         pls_integer;
      rows_processed    pls_integer;
      actual_level      pls_integer;
      element_level     pls_integer;
      element_message   varchar2 (2000);
      d_actual_istr     t_lungo;
      d_ritorno         t_lungo;
      d_messaggio_out   t_lungo;
      d_codice_out      number (10);
   begin
      actual_level := integritypackage.getnestlevel;
      for loopcnt in 1 .. d_entry
      loop
         element_level := to_number (substr (d_messaggio (loopcnt), 1, 2));
         if element_level = actual_level
            and d_istruzione (loopcnt) is not null
         then
            integritypackage.nextnestlevel;
            begin
               d_actual_istr := d_istruzione (loopcnt);
               cursor_id := DBMS_SQL.open_cursor;
               begin
                  -- controllo ed eventuale  modifica statement
                  if upper (substr (ltrim (d_istruzione (loopcnt)), 1, 6)) =
                                                                     'SELECT'
                  then
                     d_istruzione (loopcnt) :=
                                         rtrim (d_istruzione (loopcnt), ' ;');
                  else                                           -- non select
                     --se non ci sono mettere begin e end
                     if upper (substr (ltrim (d_istruzione (loopcnt)), 1, 2)) =
                                                                         ':='
                     then
                        -- AGGIUNGO LA GESTIONE DEL RITORNO
                        d_istruzione (loopcnt) :=
                              'DECLARE d_RITORNO VARCHAR2(32000);'
                           || 'BEGIN d_RITORNO'
                           || rtrim (d_istruzione (loopcnt), ' ;')
                           || '; END;';
                     elsif upper (substr (ltrim (d_istruzione (loopcnt)), 1,
                                          5)
                                 ) != 'BEGIN'
                     then
                        -- in caso di declare mette un altro begin end esterno
                        d_istruzione (loopcnt) :=
                              'BEGIN '
                           || rtrim (d_istruzione (loopcnt), ' ;')
                           || '; END;';
                     end if;
                  end if;
                  -- controllo sintattico istruzione
                  -- Tolta andata a capo chr(13) || chr(10) altrimenti
                  -- errore inspiegabile se presente... dice che la sintassi
                  -- e sbagliata
                  DBMS_SQL.parse (cursor_id,
                                  replace (d_istruzione (loopcnt),
                                           chr (13) || chr (10),
                                           ' '
                                          ),
                                  DBMS_SQL.native
                                 );
               exception
                  when others
                  then
                     sistema_messaggio_errore (sqlerrm,
                                               d_actual_istr,
                                               d_messaggio_out,
                                               d_codice_out
                                              );
                     if d_messaggio_out is not null
                     then
                        raise_application_error (d_codice_out,
                                                 d_messaggio_out
                                                );
                     else
                        raise;
                     end if;
               end;
               if upper (substr (ltrim (d_istruzione (loopcnt)), 1, 6)) =
                                                                      'SELECT'
               then
                  begin            --esecuzione istruzione e controllo errore
                     -- definizione della colonna. Serve per riuscire ad
                     -- intercettare gli errori ORA-
                     -- non importa effettivamente caricare il valore
                     DBMS_SQL.define_column (cursor_id, 1, d_ritorno, 32000);
                     --esecuzione istruzione e controllo errore
                     rows_processed := DBMS_SQL.execute (cursor_id);
                     if DBMS_SQL.fetch_rows (cursor_id) > 0
                     then
                        rows_processed := 1;
                     end if;
                  exception
                     when others
                     then
                        sistema_messaggio_errore (sqlerrm,
                                                  d_actual_istr,
                                                  d_messaggio_out,
                                                  d_codice_out
                                                 );
                        if d_messaggio_out is not null
                        then
                           raise_application_error (d_codice_out,
                                                    d_messaggio_out
                                                   );
                        else
                           raise;
                        end if;
                  end;
                  if     rows_processed > 0
                     and substr (ltrim (substr (ltrim (d_istruzione (loopcnt)),
                                                7
                                               )
                                       ),
                                 1,
                                 1
                                ) = '0'
                  then
                     element_message := substr (d_messaggio (loopcnt), 3);
                     if element_message is null
                     then
                        element_message :=
                           'Sono presenti registrazioni collegate. Operazione non eseguita.';
                     end if;
                     raise_application_error (-20008, element_message);
                  elsif     rows_processed = 0
                        and substr
                                (ltrim (substr (ltrim (d_istruzione (loopcnt)),
                                                7
                                               )
                                       ),
                                 1,
                                 1
                                ) != '0'
                  then
                     element_message := substr (d_messaggio (loopcnt), 3);
                     if element_message is null
                     then
                        element_message :=
                           'Non e'' presente la registrazione richiesta. Operazione non eseguita.';
                     end if;
                     raise_application_error (-20008, element_message);
                  end if;
               else                                 -- non statement di SELECT
                  begin
                     rows_processed := DBMS_SQL.execute (cursor_id);
                  exception
                     when integrityerror
                     then
                        raise_application_error
                                               (-20999,
                                                substr (d_messaggio (loopcnt),
                                                        3
                                                       )
                                               );
                     when others
                     then
                        -- per evitare problemi con PB e la gestione errori scrivo minuscolo
                        sistema_messaggio_errore (sqlerrm,
                                                  d_actual_istr,
                                                  d_messaggio_out,
                                                  d_codice_out
                                                 );
                        if d_messaggio_out is not null
                        then
                           raise_application_error (d_codice_out,
                                                    d_messaggio_out
                                                   );
                        else
                           raise;
                        end if;
                  end;
               end if;
               DBMS_SQL.close_cursor (cursor_id);
            end;
            integritypackage.previousnestlevel;
            d_istruzione (loopcnt) := null;
         end if;
      end loop;
   exception
   when others then
      integritypackage.initnestlevel;
      raise;
   end exec_postevent;
   procedure log
 /***********************************************************************************
 NOME:        log
 DESCRIZIONE: Emissione log se previsto debug (debug = 1).
 ARGOMENTI:   p_log: messaggio da visualizzare
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------------
 14   04/12/2008 MM     Creazione.
************************************************************************************/
   (p_log in varchar2)
   is
      d_max integer:=250;
   begin
      if debug = 1 then
         if nvl(length(p_log),0) <= d_max then
            dbms_output.put_line(p_log);
         else
            declare
               i integer;
               d_inizio integer;
               d_loop integer:=ceil(length(p_log)/d_max);
            begin
               for i in 1 .. d_loop loop
                  d_inizio := ((i - 1) * d_max) + 1;
                  dbms_output.put_line(substr(p_log, d_inizio, d_max));
               end loop;
            end;
         end if;
      end if;
   end log;
   procedure log
 /***********************************************************************************
 NOME:        log
 DESCRIZIONE: Emissione log se previsto debug (debug = 1).
 ARGOMENTI:   p_log: messaggio da visualizzare
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------------
 15   20/03/2009 MM     Creazione.
 16   13/05/2009 MM     Modificata procedure log con parametro clob.
 17   19/05/2009  MM    Modificata procedure log con parametro clob per incompatibilita
                        con oracle 8.
************************************************************************************/
   (p_log in clob)
   is
      d_max integer:=250;
      d_log varchar2(32767);
   begin
      d_log := dbms_lob.SUBSTR(p_log, 32000,1);
      if dbms_lob.GETLENGTH(p_log) > 32767 then
         d_log := d_log ||'...';
      end if;
      log(d_log);
   end log;
end integritypackage;
/* End Package Body: IntegrityPackage */
/

