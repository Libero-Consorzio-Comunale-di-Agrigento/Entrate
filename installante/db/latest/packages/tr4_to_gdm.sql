--liquibase formatted sql 
--changeset abrandolini:20250326_152429_tr4_to_gdm stripComments:false runOnChange:true 
 
create or replace package tr4_to_gdm is
/******************************************************************************
 NOME:        TR4_TO_GDM
 DESCRIZIONE: Procedure e Funzioni per invio al documentale.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   03/07/2017  VD      Prima emissione.
 001   29/08/2017  VD      Aggiunta gestione parametri per tipo comunicazione
 002   14/06/2018  VD      Modificato annullamento documenti: si annullano i
                           documenti per idrif e non per id_documento
 003   08/03/2019  VD      Funzione INVIO_DOCUMENTO: aggiunto parametro
                           nome file (facoltativo).
 004   15/02/2023  AB      Gestito il nuovo tipo_documento 'S' SOL
 005   30/01/2019  VD      Aggiunta gestione F24 con importo ridotto.
 006   10/05/2019  VD      Aggiunta gestione documenti di tipo C e D.
 007   23/02/2023  DM      Gestito reinvio dopo annullamento nel documentale
                           #62655
 008   06/09/2023  DM      #66680: Fix regressione introdotta con la #62655.
                           In presenza di un invio annullato, all'invio
                           successivo il gdm non era in grado di recuperare
                           correttamento il documento da caricare.
******************************************************************************/
wPKG_cod_integrazione      NUMBER(3) := 1;
wPkg_Area                  VARCHAR2(20) := 'TRIBUTI';
function get_ente
  return varchar2;
function get_datasource
  return varchar2;
function get_url_escape
(in_url                       in varchar2
,in_special_char              in number default 0
) return varchar2;
function get_xml
(p_select    in   varchar2
,p_rowtag    in   varchar2 default null
,p_rowsettag in   varchar2 default null
) return varchar2;
function get_xmlTesto
(p_jndi         IN   varchar2
,p_nomefile     IN   varchar2
,p_table        IN   varchar2
,p_column       IN   varchar2
,p_where        IN   VARCHAR2
) return varchar2;
function proteggi
(p_clob                       in clob
) return clob;
function proteggi
(p_clob                       in varchar2
) return varchar2;
function get_service
(p_valore                     in varchar2
) return varchar2;
function send_soap_request
(in_url                       in varchar2
,in_xml                       in clob
,in_request_type              in varchar2 default 'POST'
,in_service_timeout           in number default 600
) return clob;
function ws_finmatica_request
(in_service_url       in   varchar2
,in_xml               in   clob
,in_cod_integrazione  in   number
,in_service_timeout   in   number default 600
,in_utente            in   varchar2 default null
) return xmltype;
function sendProfiloRegistra
(p_area             in   varchar2 default '%20'
,p_modello          in   varchar2 default '%20'
,p_dati_xml         in   varchar2
,p_testoxml         in   varchar2
,p_codice_richiesta in   varchar2 default '%20'
,p_login            in   varchar2
,p_password         in   varchar2
) return varchar2;
function parseProfiloRegistraResponse
(p_response         in   varchar2
) return varchar2;
function sendProfiloUpload
(p_area             IN   varchar2 default '%20'
,p_modello          IN   varchar2 default '%20'
,p_id_documento     in   number
,p_dati_xml         IN   VARCHAR2
,p_testoxml         IN   VARCHAR2
,p_codice_richiesta IN   varchar2 default '%20'
,p_login            IN   VARCHAR2
,p_password         IN   VARCHAR2
) RETURN varchar2;
function verifica_invio_gdm
(p_cod_fiscale       in varchar2
,p_nome_file         in varchar2)
return number;
function componi_nome_file
(p_cod_fiscale       in varchar2
,p_anno              in number
,p_documento         in number
,p_tipo_documento    in varchar2)
return varchar2;
function get_tipo_comunicazione
(p_pratica           in number
,p_tipo_documento    in varchar2 default null)
return varchar2;
function genera_parametri_pnd
(p_cod_fiscale        in varchar2
,p_anno               in number
,p_documento          in number
,p_tipo_tributo       in varchar2
,p_tipo_documento     in varchar2
,p_nome_file          in varchar2 default null
,p_ni_erede           in number   default null
) return sys_refcursor;
function invio_documento
(p_cod_fiscale        in varchar2
,p_anno               in number
,p_documento          in number
,p_tipo_tributo       in varchar2
,p_tipo_documento     in varchar2
,p_login              in varchar2
,p_password           in varchar2
,p_nome_file          in varchar2 default null
) return varchar2;
function annulla_documento_tr4
(p_id_rif_gdm         in number
) return varchar2;
function aggiorna_protocollo_tr4
(p_id_documento       in number
,p_anno_protocollo    in number
,p_numero_protocollo  in number
) return varchar2;
function converti_data
(p_data_input         in varchar2
) return date;
function aggiorna_date_tr4
(p_id_documento       in number
,p_data_invio_pec     in varchar2
,p_data_ricezione_pec in varchar2
) return varchar2;
PROCEDURE invio_documento_old
(p_cod_fiscale       in varchar2
,p_anno_ruolo        in number
,p_ruolo             in number
,p_tipo_tributo      in varchar2
,p_utente            in varchar2
,p_gruppo_firma      in varchar2
,p_idDocument        in out number
,p_code_errore       out number
,p_descr_errore      out varchar2
);
/*PROCEDURE elimina_documento
(p_cm                         in varchar2
,p_id_documento               number
,p_utente                     in varchar2
,p_trg                        in varchar2 default 'N'
,p_code_errore                out number
,p_descr_errore               out varchar2
);
PROCEDURE aggiorna_gdm_docu
(p_data                       in date default to_date('01/01/2010','dd/mm/yyyy')
);
function visualizza_da_gdm
(p_entita           in varchar2
,p_id_documento     in number
,p_esercizio        in number
,p_articolo         in number
,p_utente           in varchar2 default ''
) return varchar2;
function crea_fornitura_xml
(a_progr_fornitura        in number
,a_flag_fax                   in varchar2
) return clob;
PROCEDURE INVIO_FORNITURA_XML
(a_progr_fornitura       IN NUMBER
,a_utente             in varchar2
,a_gdm_id_documento   OUT NUMBER
,a_errore             OUT varchar2
);
PROCEDURE invio_fornitura
(p_progr_fornitura               in number
,p_utente                     in varchar2
,p_idDocument                 out number
,p_code_error                 out number
,p_descr_errore               out varchar2
);
FUNCTION controlla_fornitura
(p_progr_fornitura              in number
) return varchar2;
PROCEDURE AGGIORNA_STATO_FORNITURA
(a_progr_fornitura   IN NUMBER
,a_utente     IN VARCHAR2 default null
);*/
end;
/
CREATE OR REPLACE PACKAGE BODY tr4_to_gdm IS
/******************************************************************************
 NOME:        TR4_TO_GDM
 DESCRIZIONE: Procedure e Funzioni per invio al documentale.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   03/07/2017  VD      Prima emissione.
 001   29/08/2017  VD      Aggiunta gestione parametri per tipo comunicazione
 002   31/05/2018  VD      Corretta gestione stringhe con apici nella composizione
                           della select per la produzione dell'xml (procedure
                           INVIO_DOCUMENTO).
 003   14/06/2018  VD      Modificato annullamento documenti: si annullano i
                           documenti per idrif e non per id_documento
 004   19/11/2018  VD      Aggiunta gestione istanza di accoglimento
 005   30/01/2019  VD      Aggiunta gestione F24 con importo ridotto.
 006   10/05/2019  VD      Aggiunta gestione documenti di tipo C e D.
 007   23/02/2023  DM      Gestito reinvio dopo annullamento nel documentale
                           #62655
******************************************************************************/
wPkg_Ente        constant  VARCHAR2(6)  := tr4_to_gdm.get_Ente;
wPkg_DataSource            VARCHAR2(50) := tr4_to_gdm.get_datasource;
--wdb_interno                varchar2(10) := Ge4Package.SQLExecute('select flag_db_sviluppo from euro');
function get_ente
  return varchar2
is
  dRitorno VARCHAR2(6);
begin
  begin
    select lpad(dage.pro_cliente,3,'0')||
           lpad(dage.com_cliente,3,'0')
      into dRitorno
      from dati_generali dage;
  exception
    when others then
      dRitorno := '037006';
  end;
  return dRitorno;
end;
function get_datasource
  return varchar2
is
  dRitorno VARCHAR2(50);
begin
  dRitorno := 'jdbc/tr4';
  return dRitorno;
end;
FUNCTION decode_utf8_clob (in_text IN CLOB)
  RETURN CLOB IS
  out_text                                 CLOB := in_text;
BEGIN
  -- caratteri speciali
  out_text := REPLACE (out_text, CHR (38) || 'gt;', '>');
  out_text := REPLACE (out_text, CHR (38) || 'lt;', '<');
  out_text := REPLACE (out_text, CHR (38) || 'amp;', CHR (38));
  out_text := REPLACE (out_text, CHR (38) || 'quot;', '"');
  -- eliminati perche' sconosciuti
  out_text := REPLACE (out_text, ']]>', NULL);
  -- circoletto non supportato
  out_text := REPLACE (out_text, '<![CDATA[', NULL);
  -- punto interrogativo rovesciato
  RETURN out_text;
END decode_utf8_clob;
function get_url_escape
(in_url               in varchar2
,in_special_char      in number default 0
) return varchar2
is
begin
  if in_special_char = 0 then
    return utl_url.escape(in_url,false);
  else
    return utl_url.escape(in_url,true);
  end if;
end;
FUNCTION get_service
(p_valore                     in VARCHAR2)
  RETURN VARCHAR2 IS
/******************************************************************************
NOME:        GET_SERVICE
DESCRIZIONE: Restituisce l'url, il metodo e ns specifico da richiamare per l'invio
             dei carichi per ogni cliente.
PARAMETRI:   p_valore  identificativo del dato da restituire
RITORNA:     stringa varchar2 contenente url o metodo o ns.
******************************************************************************/
  d_ritorno            VARCHAR(32000):='';
BEGIN
  if p_valore = 'URL' then
    -- provo a interrogare ws_indirizzi_integrazioni
    -- se l'indirizzo non e' ancora stato codifica, allora uso metodo statico
    begin
      scambio_dati_ws.wpkg_ws_servizio := 1;
      select w.indirizzo_url
        into d_ritorno
        from ws_indirizzi_integrazione w
       where codice_istat            = wPkg_ente
         and codice_integrazione     = wPKG_cod_integrazione
         and w.identificativo_servizio = 1
                  ;
    exception
      when others then
        d_ritorno := '';
    end;
  end if;
  if p_valore = 'SERVICE' then
     d_ritorno := '/dbfw/JVSERVICE';
  end if;
  -- al momento questo valore e' uguale per tutti i clienti
  if p_valore = 'NS' then
     d_ritorno := 'http://ws.finmatica.it/';
  end if;
  return d_ritorno;
end get_service;
---------------------------------------------------------------------------------------------------------
function get_xml
(p_select    IN   VARCHAR2,
 p_rowtag    IN   VARCHAR2 default null,
 p_rowsettag IN   VARCHAR2 default null
)
 RETURN varchar2
IS
 xmlclob     CLOB             := NULL;
 d_select    VARCHAR2 (32000);
 d_rowsettag VARCHAR2 (1000)  := nvl(p_rowsettag, 'root');
 d_rowtag    VARCHAR2 (1000)  := nvl(p_rowtag, 'field');
 d_return    VARCHAR2 (32767);
 d_count     INTEGER;
BEGIN
 -- esegue preventivamente la select per contare il numero di record
 -- che estrarra' e settare cosi' il numero di righe del XML generato
 d_select := 'select count(1) from (' ||p_select|| ') ';
 BEGIN
    EXECUTE IMMEDIATE d_select
                 INTO d_count;
 EXCEPTION
    WHEN OTHERS
    THEN
       NULL;
 END;
 -- setta il numero massimo di righe del XML
 xmlgen.setmaxrows (d_count);
-- usa l'indicatore null per indicare che una colonna ha valore nullo:
-- <COLONNA NULL="TRUE"/>
 xmlgen.useNullAttributeIndicator(true);
 -- associa all'elemento riga il tag passato
 xmlgen.setrowtag (d_rowtag);
 xmlgen.setrowsettag (d_rowsettag);
 -- ottiene XML dalla select e lo deposita nel Clob
 --integritypackage.LOG (p_select);
 xmlclob := xmlgen.getxml (p_select);
 --integritypackage.LOG (xmlclob);
 d_return := dbms_lob.substr(xmlclob, 32767, 1);
 --integritypackage.LOG (d_return);
 if instr(upper(d_return), '<ERROR>') = 0 then
    d_return := replace(replace(d_return, chr(10), ' '), chr(13), ' ');
    while instr(d_return, '  ') > 0 loop
       d_return := replace(d_return, '  ', ' ');
    end loop;
    RETURN d_return;
 else
    raise_application_error(-20999, 'Errore in TR4_TO_GDM.get_xml: '||chr(10)||d_return);
 end if;
END;
---------------------------------------------------------------------------------------------------------
   FUNCTION get_xmlTesto (
      p_jndi         IN   VARCHAR2,
      p_nomefile     IN   VARCHAR2,
      p_table        IN   VARCHAR2,
      p_column       IN   VARCHAR2,
      p_where        IN   VARCHAR2
   )
      RETURN varchar2
   IS
      d_nomefile varchar2(1000) := replace(replace(replace(p_nomefile, '''', '`'), '%','%25'),'&','e');
      d_xmltesto varchar2(2767);
   BEGIN
      IF p_jndi is not null and
         d_nomefile is not null and
         p_table is not null and
         p_column is not null and
         p_where is not null THEN
         --d_nomefile := albo_utility.GET_REPLACEDVALUE(d_nomefile);
         d_xmltesto :=
               '<root><connattach>'
            || p_jndi
            || '</connattach><tableattachname>'|| p_table ||'</tableattachname><columnattachname>'
            || d_nomefile
            || '</columnattachname><columnattach>'|| p_column ||'</columnattach><whereattachcondition>'
            || p_where
            || '</whereattachcondition><fileattach> </fileattach><deletefilefs> </deletefilefs><deletefiledb>N</deletefiledb></root>';
      ELSE
         d_xmltesto := ' ';
      END IF;
      return d_xmltesto;
   END;
---------------------------------------------------------------------------------------------------------
 /* Function Private */
function get_value_by_tag(
   p_xml IN VARCHAR2,
   p_tag IN VARCHAR2
)
      return varchar2
is
   d_pos1 integer;
   d_pos2 integer;
   d_return varchar2(32767);
begin
   d_pos1 := instr(lower(p_xml), '<'||lower(p_tag));
   if d_pos1 > 0 then
      d_pos1 := instr(p_xml, '>', d_pos1);
      if d_pos1 > 0 then
         d_pos1 := d_pos1 + 1;
         d_pos2 := instr(lower(p_xml), '</'|| lower(p_tag) ||'>');
         if d_pos2 > 0 and d_pos2 > d_pos1 then
            d_return := substr(p_xml, d_pos1, d_pos2 - d_pos1);
         else
            d_pos2 := 0;
         end if;
      end if;
   end if;
   if d_pos1 = 0 or d_pos2 = 0 then
      d_return := '';
   end if;
   return d_return;
end;
function add_clob (in_clob IN CLOB, in_text IN VARCHAR2)
  RETURN CLOB
IS
  out_clob                                  CLOB := EMPTY_CLOB();
  len                                       BINARY_INTEGER := 32000;
begin
  DBMS_LOB.createtemporary (out_clob, TRUE, DBMS_LOB.SESSION);
  IF NVL (DBMS_LOB.getlength (in_clob), 0) > 0 THEN
     out_clob := in_clob;
  END IF;
  IF in_text IS NOT NULL THEN
     len := LENGTH (in_text);
     DBMS_LOB.writeappend (out_clob, len, in_text);
  END IF;
  RETURN out_clob;
end add_clob;
FUNCTION decode_utf8 (in_text IN VARCHAR2)
  RETURN VARCHAR2 IS
  out_text                    VARCHAR2 (32000):= in_text;
BEGIN
  -- lettere accentate
  out_text := REPLACE (out_text, CHR (224), 'A''');
  out_text := REPLACE (out_text, CHR (232), 'E''');
  out_text := REPLACE (out_text, CHR (233), 'E''');
  out_text := REPLACE (out_text, CHR (236), 'I''');
  out_text := REPLACE (out_text, CHR (242), 'O''');
  out_text := REPLACE (out_text, CHR (249), 'U''');
  -- caratteri speciali
  out_text := REPLACE (out_text, CHR (38) || 'apos;', '''');
  out_text := REPLACE (out_text, CHR (38) || 'quot;', '"');
  out_text := REPLACE (out_text, CHR (38) || 'gt;', '>');
  out_text := REPLACE (out_text, CHR (38) || 'lt;', '<');
  out_text := REPLACE (out_text, CHR (38) || 'amp;', CHR (38));
  -- eliminati perche' sconosciuti
  out_text := REPLACE (out_text, CHR (176), '');
  -- circoletto non supportato
  out_text := REPLACE (out_text, CHR (128), '');
  -- punto interrogativo rovesciato
  RETURN out_text;
END decode_utf8;
function proteggi
(p_clob IN CLOB
) return clob
is
  wOutText   CLOB := p_clob;
begin
  -- lettere accentate
  wOutText := REPLACE (wOutText, 'A''', CHR (224));
  wOutText := REPLACE (wOutText, 'E''', CHR (232));
  wOutText := REPLACE (wOutText, 'E''', CHR (233));
  wOutText := REPLACE (wOutText, 'I''', CHR (236));
  wOutText := REPLACE (wOutText, 'O''', CHR (242));
  wOutText := REPLACE (wOutText, 'U''', CHR (249));
  -- caratteri speciali
  wOutText := REPLACE (wOutText, '''', CHR (38) || 'apos;');
  wOutText := REPLACE (wOutText, '"',  CHR (38) || 'quot;');
  wOutText := REPLACE (wOutText, '>',  CHR (38) || 'gt;');
  wOutText := REPLACE (wOutText, '<',  CHR (38) || 'lt;');
  wOutText := REPLACE (wOutText, CHR (38), CHR (38) || 'amp;');
  -- eliminati perche' sconosciuti
  wOutText := REPLACE (wOutText, CHR (176), '');
  -- circoletto non supportato
  wOutText := REPLACE (wOutText, CHR (128), '');
  -- punto interrogativo rovesciato
--      RETURN '<![CDATA['||wOutText||']]>';
  RETURN wOutText;
end proteggi;
FUNCTION proteggi
(p_clob                       in varchar2
) return varchar2
is
      wOutText   VARCHAR2(2000) := p_clob;
begin
  -- lettere accentate
  wOutText := REPLACE (wOutText, 'A''', CHR (224));
  wOutText := REPLACE (wOutText, 'E''', CHR (232));
  wOutText := REPLACE (wOutText, 'E''', CHR (233));
  wOutText := REPLACE (wOutText, 'I''', CHR (236));
  wOutText := REPLACE (wOutText, 'O''', CHR (242));
  wOutText := REPLACE (wOutText, 'U''', CHR (249));
  -- caratteri speciali
  wOutText := REPLACE (wOutText, '''', CHR (38) || 'apos;');
  wOutText := REPLACE (wOutText, '"',  CHR (38) || 'quot;');
  wOutText := REPLACE (wOutText, '>',  CHR (38) || 'gt;');
  wOutText := REPLACE (wOutText, '<',  CHR (38) || 'lt;');
  wOutText := REPLACE (wOutText, CHR (38), CHR (38) || 'amp;');
  -- eliminati perche' sconosciuti
  wOutText := REPLACE (wOutText, CHR (176), '');
  -- circoletto non supportato
  wOutText := REPLACE (wOutText, CHR (128), '');
  -- punto interrogativo rovesciato
--      RETURN '<![CDATA['||wOutText||']]>';
  RETURN wOutText;
end proteggi;
function clob_to_xml(p_clob in clob)
  RETURN xmltype
is
  d_response                  CLOB;
  d_xmlresponse               xmltype;
  pos                         NUMBER;
  pos2                        NUMBER;
  repl                        VARCHAR2 (2000);
  tmp_clob                    CLOB;
begin
  d_response := decode_utf8_clob (p_clob);
  pos := tr4_clob.INSTR (d_response, 'xmlns', 1, 1);
  WHILE pos <> 0 LOOP
     pos2 := tr4_clob.INSTR (d_response, '>', pos, 1);
     repl := tr4_clob.SUBSTR (d_response, pos, pos2 - pos);
     tmp_clob := tr4_clob.REPLACE (d_response, repl, '');
     pos := tr4_clob.INSTR (d_response, 'xmlns', pos2, 1);
  END LOOP;
  d_xmlresponse := XMLTYPE.createxml (d_response);
  return d_xmlresponse;
end;
FUNCTION sendrequest (
  p_request    IN   VARCHAR2,
  p_user       IN   VARCHAR2 DEFAULT NULL,
  p_password   IN   VARCHAR2 DEFAULT NULL
)
  RETURN VARCHAR2
IS
  d_request     VARCHAR2 (30000);
  d_response    VARCHAR2 (30000);
  d_http_req    UTL_HTTP.req;
  d_http_resp   UTL_HTTP.resp;
BEGIN
    d_request := get_service('URL')||get_service('SERVICE')||'?'||p_request;
    d_request := utl_url.ESCAPE (d_request);
    /*IF INSTR (LOWER (d_request), 'https') > 0
    THEN
       UTL_HTTP.set_wallet (get_wallet, get_wallet_pwd);
    END IF;*/
    d_http_req :=
            UTL_HTTP.begin_request (d_request, 'GET', 'HTTP/1.1');
    IF p_user IS NOT NULL
    THEN
       UTL_HTTP.set_authentication (d_http_req, p_user, p_password);
    END IF;
    d_http_resp := UTL_HTTP.get_response (d_http_req);
    begin
       UTL_HTTP.read_text (d_http_resp, d_response);
       UTL_HTTP.end_response (d_http_resp);
    EXCEPTION
       WHEN UTL_HTTP.end_of_body
       THEN
          UTL_HTTP.end_response (d_http_resp);
       WHEN OTHERS
       THEN
          raise;
    end;
    RETURN d_response;
EXCEPTION
    WHEN others then
    UTL_HTTP.end_response (d_http_resp);
    raise_application_error (-20999,
                                d_http_resp.status_code
                             || ' - '
                             || d_http_resp.reason_phrase,
                             TRUE
                            );
END;
function send_soap_request
(in_url                 in varchar2
,in_xml                 in clob
,in_request_type        in varchar2 default 'POST'
,in_service_timeout     in number default 600
) return clob
is
  m_request                                      clob := nvl(in_xml,' ');
  m_response                                     clob;
  m_response_5000                                clob;
  m_response_line                                varchar2 (32000);
  http_request                                   utl_http.req;
  http_response                                  utl_http.resp;
  i                                              number := 0;
  tmp_chunk                                      number := 32000;
  tmp_amount                                     number;
  tmp_content                                    varchar2(100);
  d_user                                         varchar2(20);
  d_password                                     varchar2(40);
  d_request                                      VARCHAR2 (30000);
begin
  tmp_content := case in_request_type
                   when 'POST' then 'application/x-www-form-urlencoded'
                   when 'GET'  then 'text/xml'
                 end;
  utl_http.set_transfer_timeout (in_service_timeout);
  IF in_request_type = 'GET' then
     -- in questo caso tutto il messaggio url+xml va nel primo parametro
     http_request := utl_http.begin_request (in_url||'?'||in_xml, in_request_type, 'HTTP/1.1');
     --d_user := 'GE4';
     d_user := 'GDM';
     --d_password := 'lavoro17';
     select rtrim(translate( translate(substr(password,7,3),chr(7),' ')||
                        translate(substr(password,4,3),chr(7),' ')||
                        translate(substr(password,1,3),chr(7),' ')||
                        substr(password,10)
                       ,chr(1)||'THE'||chr(5)||'qui'||chr(2)||'k1y2'
                        ||chr(4)||'OX3j~'||chr(3)||'p4@V#R5lazY6D%GS7890'
                       ,'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789~@#%')) PASSWORD
      into d_password
      from ad4_utenti
     where utente = d_user
     ;
     --dbms_output.put_line('d_user/pwd: '||d_user||'/'||nvl(d_password,''));
     UTL_HTTP.set_authentication (http_request, d_user, nvl(d_password,''));
  ELSE
     http_request := utl_http.begin_request (in_url, in_request_type, 'HTTP/1.1');
     utl_http.set_persistent_conn_support(http_request, true);
     utl_http.set_header (http_request, 'Content-Type',tmp_content);
     tmp_amount := length(m_request);
     utl_http.set_header (http_request, 'Content-Length', tmp_amount);
     tmp_chunk := least(tmp_chunk,tmp_amount);
     for i in 0..trunc(tmp_amount/tmp_chunk)
     loop
       utl_http.write_text(http_request,tr4_clob.substr(m_request,1+(i*tmp_chunk),tmp_chunk));
     end loop;
     if mod(tmp_amount,tmp_chunk) > 0 then
       utl_http.write_text(http_request,tr4_clob.substr(m_request,1+((trunc(tmp_amount/tmp_chunk))*tmp_chunk),mod(tmp_amount,tmp_chunk)));
     end if;
  END IF;
 --dbms_output.put_line(m_request);
  --dbms_output.put_line('inizio ricezione');
  http_response:= utl_http.get_response(http_request);
  begin
    loop
      i:= i + 1;
      utl_http.read_line(http_response, m_response_line,false);
      m_response_5000 := add_clob(m_response_5000,decode_utf8(m_response_line));
      if mod(i,5000)=0 then
        m_response      := m_response||m_response_5000;
        m_response_5000 := null;
      end if;
    end loop;
    utl_http.end_response(http_response);
  exception
    when utl_http.end_of_body then
       utl_http.end_response(http_response);
    when others then
       dbms_output.put_line(sqlerrm);
  end;
  m_response := m_response||m_response_5000;
  return m_response;
exception when others then
  utl_http.end_response(http_response);
end send_soap_request;
FUNCTION get_header (p_tipo in varchar2, p_cod_integrazione in NUMBER)
 RETURN VARCHAR2 IS
 /******************************************************************************
 NOME:        GET_HEADER
 DESCRIZIONE: Restituisce la stringa da mettere nella UTL_HTTP.set_header
 PARAMETRI:   p_tipo tipo di valore da restituire (Content-Type O SOAPAction)
              p_cod_integrazione  identificativo del cliente
 RITORNA:     stringa varchar2 contenente url
 ******************************************************************************/
    d_ritorno            VARCHAR(32000):='';
 BEGIN
    BEGIN
       IF p_tipo = 'Content-Type' then
          select w.header_type
            into d_ritorno
            from ws_indirizzi_integrazione w
           where codice_istat              = wPkg_Ente
             and codice_integrazione       = p_cod_integrazione
             and w.identificativo_servizio = scambio_dati_ws.wpkg_ws_servizio
                  ;
       ELSE
           select nvl(w.header_action,'')
            into d_ritorno
            from ws_indirizzi_integrazione w
           where codice_istat              = wPkg_Ente
             and codice_integrazione       = p_cod_integrazione
             and w.identificativo_servizio = scambio_dati_ws.wpkg_ws_servizio
                  ;
       END IF;
    EXCEPTION
        when no_data_found then
          raise_application_error(-20999,'Occorre gestire la tabella WS_INDIRIZZI_INTEGRAZIONE ('
                                  ||scambio_dati_ws.get_descr_integrazione(p_cod_integrazione)||')');
    END;
    return d_ritorno;
END get_header;
FUNCTION ws_finmatica_request
(in_service_url       IN   VARCHAR2
,in_xml               IN   CLOB
,in_cod_integrazione  IN   NUMBER
,in_service_timeout   IN   NUMBER DEFAULT 600
,in_utente            IN   VARCHAR2 DEFAULT NULL
)   RETURN XMLTYPE
IS
  soap_request                                      CLOB;
  soap_response                                     CLOB;
  soap_response_5000                                CLOB;
  soap_response_line                                VARCHAR2 (32767);
  http_request                                      UTL_HTTP.req;
  http_response                                     UTL_HTTP.resp;
  out_xml                                           XMLTYPE;
  i                                                 NUMBER := 0;
  d_Identificativo                                  varchar2(40);
  tmp_chunk                                         number := 32000;
  tmp_amount                                        number;
  d_password                                        varchar2(200);
  --name                                              varchar2(255);
BEGIN
      /* formattazione richiesta da inviare */
      soap_request := scambio_dati_ws.get_soap_request(in_xml, in_cod_integrazione, wPKG_ente);
--dbms_output.put_line('Soap request');
      UTL_HTTP.set_transfer_timeout (in_service_timeout);
--dbms_output.put_line('transfer timeout');
      http_request := UTL_HTTP.begin_request (in_service_url, 'POST', 'HTTP/1.1');
--dbms_output.put_line('Begin request');
      -- autenticazione
      if in_utente is not null then
        /*select rtrim(translate( translate(substr(password,7,3),chr(7),' ')||
                        translate(substr(password,4,3),chr(7),' ')||
                        translate(substr(password,1,3),chr(7),' ')||
                        substr(password,10)
                       ,chr(1)||'THE'||chr(5)||'qui'||chr(2)||'k1y2'
                        ||chr(4)||'OX3j~'||chr(3)||'p4@V#R5lazY6D%GS7890'
                       ,'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789~@#%')) PASSWORD
          into d_password
          from ad4_utenti
         where utente = in_utente
         ;
         UTL_HTTP.set_authentication (http_request, in_utente, nvl(d_password,''));
         */
         select rtrim(translate( translate(substr(password,7,3),chr(7),' ')||
                        translate(substr(password,4,3),chr(7),' ')||
                        translate(substr(password,1,3),chr(7),' ')||
                        substr(password,10)
                       ,chr(1)||'THE'||chr(5)||'qui'||chr(2)||'k1y2'
                        ||chr(4)||'OX3j~'||chr(3)||'p4@V#R5lazY6D%GS7890'
                       ,'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789~@#%')) PASSWORD
          into d_password
          from ad4_utenti
         where utente = 'GDM'
         ;
--dbms_output.put_line('Password: '||d_password);
         UTL_HTTP.set_authentication (http_request, 'GDM', nvl(d_password,''));
      end if;
--dbms_output.put_line('Set authentication');
      utl_http.set_persistent_conn_support(http_request, true);
--dbms_output.put_line('Set persistent');
      UTL_HTTP.set_header (http_request, 'SOAPAction', get_header('SOAPAction',in_cod_integrazione));
--dbms_output.put_line('Set header 1: ');
      UTL_HTTP.set_header (http_request, 'Content-Length', LENGTH (soap_request));
--dbms_output.put_line('Set header 2');
      UTL_HTTP.set_header (http_request, 'Content-Type',get_header('Content-Type',in_cod_integrazione));
--dbms_output.put_line('Set header 3');
/*update documenti_contribuente
set xmlsend = soap_request
where cod_fiscale = 'CRSMNL77R20B157F'
and sequenza = 1;
commit;*/
      -- eventuale suddivisione in "pezzi" della richiesta
      tmp_amount := tr4_clob.length(soap_request);
      tmp_chunk := least(tmp_chunk,tmp_amount);
      for i in 0..trunc(tmp_amount/tmp_chunk)
         loop
         utl_http.write_text(http_request,tr4_clob.substr(soap_request,1+(i*tmp_chunk),tmp_chunk));
      end loop;
      if mod(tmp_amount,tmp_chunk) > 0 then
         utl_http.write_text(http_request,tr4_clob.substr(soap_request,1+((trunc(tmp_amount/tmp_chunk))*tmp_chunk),mod(tmp_amount,tmp_chunk)));
      end if;
--dbms_output.put_line('Suddivisione richiesta');
      -- invio richiesta
      http_response := UTL_HTTP.get_response (http_request);
--dbms_output.put_line('Invio richiesta');
       /*FOR i IN 1..utl_http.get_header_count(http_response)
       LOOP
       utl_http.get_header(http_response, i, name, value);
       insert into estav_ws_xmldoc(doc_id, doc_type,xmlsend)
       values (i,'DOC',name || ': ' || value);
       commit;
       END LOOP;*/
      BEGIN
       LOOP
          i := i + 1;
          UTL_HTTP.read_line (http_response, soap_response_line, FALSE);
          soap_response_5000 :=
             add_clob (soap_response_5000
                     , decode_utf8 (soap_response_line));
          IF MOD (i, 500) = 0 THEN
             NULL;
          END IF;
          IF MOD (i, 5000) = 0 THEN
             soap_response := soap_response || soap_response_5000;
             soap_response_5000 := NULL;
          END IF;
       END LOOP;
--dbms_output.put_line('Read line');
           UTL_HTTP.end_response (http_response);
        EXCEPTION
           WHEN UTL_HTTP.end_of_body THEN
              UTL_HTTP.end_response (http_response);
        END;
      soap_response := soap_response || soap_response_5000;
--dbms_output.put_line('Soap response 5000');
      --  soap_response := pi_unwrap_hl7(soap_response);
      soap_response := scambio_dati_ws.elimina_tag_versione(soap_response);
      out_xml := XMLTYPE.createxml (soap_response);
--dbms_output.put_line('Outxml');
      RETURN out_xml;
   EXCEPTION
      WHEN OTHERS
      THEN
         UTL_HTTP.end_response (http_response);
END ws_finmatica_request;
function intesta_istruzione
(p_istruzione                 in varchar2
,p_area                       in varchar2
,p_cm                         in varchar2
,p_idDocumento                in number
) return clob
is
  d_istruzione clob;
begin
  -- restituisce la parte iniziale dell'istruzione che e' uguale per tutte le istruzioni
  -- da noi richiamate
  d_istruzione := 'istruzione='
               ||p_istruzione
               ||'&soacostruttore=request%23C%23C%23'
               ||'jdms%23'
               ||'area%23'||p_area||'%23'
               ||'cm%23'||p_cm||'%23cr%23%20%23';
  -- se l'istruzione e' la ricerca non bisogna passare il parametro idDocument
  if p_istruzione != 'IQueryRicerca' then
    if p_idDocumento is null then
       d_istruzione := d_istruzione || 'idDocument%23%20';
    else
       d_istruzione := d_istruzione || 'idDocument%23'||p_idDocumento||'%20';
    end if;
  end if;
  d_istruzione := d_istruzione ||'&'||'app=jdms';
  return d_istruzione;
end;
function gestisci_istruzione_allegato
(p_chiave in number
) return clob
is
  d_istruzione clob;
BEGIN
  -- gestisce la parte di istruzione a seconda che ci sia o meno l'allegato da
  -- inserire nel documentale
  d_istruzione := '&'||'allegatiXML=';
  if p_chiave is null then
   -- se la chiave e'  nulla ==> non ci sono allegati
    d_istruzione := d_istruzione|| '%20';
  else
    d_istruzione := d_istruzione
                 || '<root><connattach>'||wPkg_DataSource||'</connattach>'
                 || '<tableattachname>TEMP_CLOB</tableattachname>'
                 || '<columnattachname>NOME_FILE</columnattachname>'
                 || '<columnattach>DOCUMENTO_BLOB</columnattach>'
                 || '<whereattachcondition>PROGR_TEMP_CLOB='||p_chiave||'</whereattachcondition>'
                 || '<fileattach></fileattach>'
                 || '<deletefilefs>N</deletefilefs>'
                 || '<deletefiledb>N</deletefiledb>'
                 || '</root>';
  end if;
  return d_istruzione;
end;
function termina_istruzione
(p_istruzione                 in varchar2
,p_stato                      in varchar2
) return clob
is
  d_istruzione clob;
begin
   -- restituisce la parte finale dell'istruzione
  if p_istruzione = 'ProfiloRegistra' then
     d_istruzione := '&aclXML=%20'
                   ||'&'||'stato='||p_stato
                   ||'&'||'escludiControlloCompetenze=N'
                   ||'&'||'setFather=%20'
                   ||'&'||'addIntoFolder=%20'
                   ||'&'||'removeFromFolder=%20';
  end if;
  return d_istruzione;
end;
PROCEDURE interpreta_response
(p_response                           clob
,p_IDDocumento                        out number
,p_descrErrore                        out varchar2
,p_codeErrore                         out number)
IS
  i       number;
  pos                                               NUMBER;
  pos2                                              NUMBER;
  repl                                              VARCHAR2 (2000);
  tmp_clob                                          CLOB;
  d_response                                        CLOB:= p_response;
  d_documentoID                                     varchar2(40);
  d_descrerr                                        varchar2(2000);
  d_codresp                                         varchar2(5);
  xmlresponse                                       xmltype;
BEGIN
   IF d_response is not null THEN
        -- mostro a video il contenuto della risposta
       /* FOR i IN 0 .. NVL (LENGTH (d_response) / 250, 0) LOOP
           DBMS_OUTPUT.put_line (SUBSTR (d_response
                                       , (i * 250) + 1
                                       , 250
                                        )
                                );
        END LOOP;*/
        -- tratto la risposta per trasformarle in xml
        xmlresponse := clob_to_xml(d_response);
        /* se la chiamata e' andato a buon fine l'xml di risposta contiene
        l'idDocumento generato o trattato*/
        IF xmlresponse.EXISTSNODE ('//IDDOCUMENT') > 0 THEN
           SELECT xmlresponse.EXTRACT
                       ('//IDDOCUMENT/text()'
                      , 'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"'
                       ).getstringval ()
               INTO d_documentoID
               FROM DUAL;
               p_idDocumento := to_number(d_documentoID);
               p_codeErrore := null;
               p_descrErrore := null;
           ELSE
             /* se ho avuto un errore la risposta e' del tipo
                <message>
                   <result>error</result>
                   <type>ERROR_PARAMETER</type>
                   <code/>
                   <text>Descrizione tipo di Errore</text>
                </message>
            */
             SELECT xmlresponse.EXTRACT
                       ('//text/text()'
                      , 'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"'
                       ).getstringval (),
                     xmlresponse.EXTRACT
                       ('//code/text()'
                      , 'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"'
                       ).getstringval ()
               INTO d_descrerr, d_codresp
               FROM DUAL;
               p_codeErrore := to_number(d_codresp);
               p_descrErrore := d_descrErr;
               p_idDocumento := null;
           END IF;
   ELSE
      p_codeErrore := -20999;
      p_descrErrore := 'Errore in ricezione della risposta';
      p_IDDocumento := null;
   END IF;
END;
---------------------------------------------------------------------------------------------------------
   function sendProfiloRegistra (
      p_area             IN   varchar2 default '%20',
      p_modello          IN   varchar2 default '%20',
      p_dati_xml         IN   VARCHAR2,
      p_testoxml         IN   VARCHAR2,
      p_codice_richiesta IN   varchar2 default '%20',
      p_login            IN   VARCHAR2,
      p_password         IN   VARCHAR2
   )
      RETURN VARCHAR2
   is
      d_servlet               varchar2(1000) := nvl(f_inpa_valore('GDM_SERL'),'restrict/JVSERVICE');
      d_service               varchar2(100)  := nvl(f_inpa_valore('GDM_SERV'),'http://svi-ora03/dbfw');
      d_login                 varchar2(100);
      d_utente                varchar2(8);
      d_password              varchar2(100);
      d_response              varchar2(32767);
      d_id_documento          varchar2(4000);
      d_testoXml              varchar2(32767) := p_testoXml;
      d_istruzione            varchar2(32767);
      d_parametri             varchar2(32767);
   begin
      if p_login is null then
         d_login := f_inpa_valore('GDM_LOGIN');
         if instr(d_login,'/',1) > 0 then
            d_utente := substr(d_login,1,instr(d_login,'/',1) - 1);
            d_password := substr(d_login,instr(d_login,'/',1) + 1);
         else
            d_utente := d_login;
            d_password := d_login;
         end if;
      else
         d_utente := p_login;
         d_password := p_password;
      end if;
      --
      d_istruzione := 'istruzione=ProfiloRegistra';
      d_parametri := 'soacostruttore=request#C#C#jdms#area#'
             || p_area
             || '#cm#'
             || p_modello
             || '#cr#'
             || p_codice_richiesta
             || '#idDocument# '|| chr(38)
             || 'app=jdms' || chr(38)
             || 'datiXML=' || p_dati_xml||chr(38)
             || 'aclXML=' || chr(38)
             || 'stato=BO' || chr(38)
             || 'escludiControlloCompetenze=N' || chr(38)
             || 'setFather=' || chr(38)
             || 'addIntoFolder=' || chr(38)
             || 'removeFromFolder=' || chr(38)
             || 'allegatiXML='|| d_testoXml;
/*dbms_output.put_line('SendProfiloRegistra');
dbms_output.put_line(substr(d_parametri,1,250));
dbms_output.put_line(substr(d_parametri,251,250));
dbms_output.put_line(substr(d_parametri,501,250));
dbms_output.put_line(substr(d_parametri,751,250));
dbms_output.put_line(substr(d_parametri,1001,250));
dbms_output.put_line(substr(d_parametri,1251,250));
dbms_output.put_line(substr(d_parametri,1501,250));
dbms_output.put_line(substr(d_parametri,1751,250));
dbms_output.put_line(substr(d_parametri,2001,250));
dbms_output.put_line(substr(d_parametri,2251,250));
dbms_output.put_line(substr(d_parametri,2501,250));
dbms_output.put_line(substr(d_parametri,2751,250));
dbms_output.put_line('Fine SendProfiloRegistra');*/
/*dbms_output.put_line('Service: '||d_service);
dbms_output.put_line('Servlet: '||d_servlet);
*/
      afc_http.set_service_url (d_service);
      d_response :=
         afc_http.sendsoarequest
            (d_servlet,
             d_istruzione,
             d_parametri,
             d_utente,
             d_password
            );
/*dbms_output.put_line('-> afc_http.set_service_url');
dbms_output.put_line(substr(d_response,1,250));
dbms_output.put_line(substr(d_response,251,250));
dbms_output.put_line(substr(d_response,501,250));
dbms_output.put_line(substr(d_response,751,250));
dbms_output.put_line(substr(d_response,1001,250));
dbms_output.put_line(substr(d_response,1251,250));
dbms_output.put_line(substr(d_response,1501,250));
dbms_output.put_line(substr(d_response,1751,250));
dbms_output.put_line(substr(d_response,2001,250));
dbms_output.put_line(substr(d_response,2251,250));
dbms_output.put_line(substr(d_response,2501,250));
dbms_output.put_line(substr(d_response,2751,250));
dbms_output.put_line('-> Fine afc_http.set_service_url');*/
      RETURN d_response;
   END;
---------------------------------------------------------------------------------------------------------
   function parseProfiloRegistraResponse
   (p_response         IN   VARCHAR2
   ) return varchar2
   is
      d_id_documento   varchar2(4000);
      d_type           varchar2(100);
      d_code           varchar2(100);
      d_text           varchar2(4000);
   BEGIN
      /* La response ritorna in caso di errore una stringa del tipo:
         <message>
            <result>error</result>
            <type>ERROR_PARAMETER</type>
            <code>CODE</code>
            <text>ErrorText</text>
         </message>
        La response ritorna in caso di successo una stringa del tipo:
         <ROWSET requestId="1" pages="1" page="1" lastRow="1" rows="1" firstRow="1" >
            <ROW num="1">
               <IDDOCUMENT type="null" size="null" >12563876</IDDOCUMENT>
            </ROW>
         </ROWSET>
      */
      BEGIN
         IF INSTR (p_response, '>error<') > 0
         THEN
            d_type := get_value_by_tag (p_response, 'type');
            d_code := get_value_by_tag (p_response, 'code');
            d_text := get_value_by_tag (p_response, 'text');
            raise_application_error (-20999,
                                        NVL (d_type, 'Type non presente')
                                     || ': '
                                     || NVL (d_text, 'Text non presente')
                                     || ' ('
                                     || NVL (d_code, 'Code non presente')
                                     || ')'
                                    );
         ELSE
            d_id_documento := get_value_by_tag (p_response, 'iddocument');
            IF d_id_documento IS NULL
            THEN
               raise_application_error
                              (-20999,
                                  'Impossibile recuperare id del documento: '
                               || p_response
                              );
            END IF;
         END IF;
      END;
      RETURN d_id_documento;
   END;
   function sendProfiloUpload (
      p_area             IN   varchar2 default '%20',
      p_modello          IN   varchar2 default '%20',
      p_id_documento     in   number,
      p_dati_xml         IN   VARCHAR2,
      p_testoxml         IN   VARCHAR2,
      p_codice_richiesta IN   varchar2 default '%20',
      p_login            IN   VARCHAR2,
      p_password         IN   VARCHAR2
   )
      RETURN VARCHAR2
   is
      d_conn_jndi varchar2(50) := 'jdbc/tr4';
      d_cod_fiscale varchar2(16) := 'CRSMNL77R20B157F';
      d_nome_file varchar2(100) := 'COM_20150000002604_CRSMNL77R20B157F.pdf';
      d_servlet        VARCHAR2 (1000) := 'restrict/JVSERVICE';
      --          := nvl(installazione_parametro.get_valore ('ALBO_SERVLET'), 'JVSERVICE');
      d_service        VARCHAR2 (100) := 'http://svi-j01:8088/dbfw';
      --          := installazione_parametro.get_valore ('ALBO_SERVIZIO')
      --             || '/dbfw';
      d_utente         VARCHAR2 (8) := 'GDM';
/*         := NVL (p_login,
                 NVL (installazione_parametro.get_valore ('ALBO_LOGIN'), 'GDM')
                );*/
      d_password       VARCHAR2 (100) := 'GDM';
/*         := NVL (p_password,
                 NVL (installazione_parametro.get_valore ('ALBO_PASSWORD'),
                      d_utente
                     )
                );*/
      d_response        VARCHAR2 (32767);
      d_id_documento    varchar2(4000);
      d_testoXml        VARCHAR2 (32767) := p_testoXml;
      d_istruzione      VARCHAR2(32767);
      d_parametri       VARCHAR2(32767);
   BEGIN
      d_istruzione := 'istruzione=ProfiloUpload';
      d_parametri := 'soacostruttore=request#C#C#jdms#area#'
             || '%20' --p_area
             || '#cm#'
             || '%20' --p_modello
             || '#cr#'
             || '%20' --p_codice_richiesta
             || '#idDocument# '||2067|| chr(38)
             || 'app=jdms'||chr(38)
             || 'connAttach='||d_conn_jndi|| chr(38)
             || 'tableAttachName=DOCUMENTI_CONTRIBUENTE'||chr(38)
             || 'columnAttachName=NOME_FILE'||chr(38)
             || 'columnAttach=DOCUMENTO'||chr(38)
             || 'whereAttachCondition=cod_fiscale='''||d_cod_fiscale||''' and nome_file='''||d_nome_file||''''||chr(38)
             || 'fileAttach= &deleteFileFs=Y&deleteFileDb=N';
/*dbms_output.put_line(substr(d_parametri,1,250));
dbms_output.put_line(substr(d_parametri,251,250));
dbms_output.put_line(substr(d_parametri,501,250));
dbms_output.put_line(substr(d_parametri,751,250)); */
/*             ||'datiXML='
             || p_dati_xml
             ||chr(38)||'aclXML='||chr(38)||'stato=BO'||chr(38)||'escludiControlloCompetenze=N'||chr(38)||'setFather='||chr(38)||'addIntoFolder='||chr(38)||'removeFromFolder='||chr(38)||'allegatiXML='
             --||chr(38)||'aclXML=%20'||chr(38)||'stato=BO'||chr(38)||'escludiControlloCompetenze=N'||chr(38)||'setFather=%20'||chr(38)||'addIntoFolder=%20'||chr(38)||'removeFromFolder=%20'||chr(38)||'allegatiXML='
             || d_testoXml;*/
/*      integritypackage.LOG('d_service');
      integritypackage.LOG(d_service);
      integritypackage.LOG('d_servlet');
      integritypackage.LOG(d_servlet);
      integritypackage.LOG('d_istruzione');
      integritypackage.LOG(d_istruzione);
      integritypackage.LOG('d_parametri');
      integritypackage.LOG(d_parametri);
      integritypackage.LOG('-----------------------------------------------------------------');*/
      afc_http.set_service_url (d_service);
      d_response :=
         afc_http.sendsoarequest
            (d_servlet,
             d_istruzione,
             d_parametri,
             d_utente,
             d_password
            );
      RETURN d_response;
   END;
---------------------------------------------------------------------------------------------------------
function verifica_invio_gdm
(p_cod_fiscale       in varchar2
,p_nome_file         in varchar2)
return number
is
/******************************************************************************
 NOME:        VERIFICA_INVIO_GDM
 DESCRIZIONE: Verifica se il file indicato è già stato inviato al documentale.
 PARAMETRI:   p_cod_fiscale        Codice fiscale del contribuente
              p_anno               Anno di riferimento del documento
                                   Valorizzato solo per i ruolo, altrimenti
                                   vale 0.
              p_documento          Numero documento
                                   Se si tratta di comunicazione a ruolo,
                                   contiene il numero del ruolo; negli altri
                                   casi contiene il numero della pratica
              p_tipo_tributo       Tipo tributo (ICI/TASI/TARSU ecc.)
              p_tipo_documento     Identifica il tipo di documento da trattare
                                   S - Avviso di pagamento (comunicazione a ruolo)
                                   A - Accertamento
                                   L - Liquidazione
                                   I - Accoglimento Istanza
                                   F - F24 (Allegato)
                                   FI - F24 importo ridotto (Allegato)
                                   FR - F24 (Allegato a pratica rateizzata)
                                   PR - Piando di Rimborso (Allegato a pratica rateizzata)
              p_login              User oracle di GDM (viene passato a null e
                                   reperito dalla tabella INSTALLAZIONE_PARAMETRI)
              p_password           Password dello user oracle di GDM (viene
                                   passato a null e reperito dalla tabella
                                   INSTALLAZIONE_PARAMETRI
              p_nome_file          facoltativo - se non presente si compone
                                   secondo le regole previste
 RITORNA:     NUMBER               0 - documento non presente o non ancora inviato
                                   1 - documento inviato a GDM
                                   2 - documento protocollato
                                   3 - PEC inviata
                                   4 - PEC ricevuta
 NOTE:
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   08/03/2019  VD      Prima emissione.
******************************************************************************/
d_ritorno                  number;
begin
  begin
    select max(decode(data_ricezione_pec
                 ,null,decode(data_invio_pec
                             ,null,decode(numero_protocollo
                                         ,null,decode(id_documento_gdm
                                                     ,null,0
                                                          ,1)
                                              ,2)
                                  ,3)
                      ,4))
      into d_ritorno
      from documenti_contribuente
     where cod_fiscale = p_cod_fiscale
       and nome_file   = p_nome_file;
  exception
    when no_data_found then
      d_ritorno := 0;
  end;
  return d_ritorno;
end;
---------------------------------------------------------------------------------------------------------
function componi_nome_file
(p_cod_fiscale       in varchar2
,p_anno              in number
,p_documento         in number
,p_tipo_documento    in varchar2)
return varchar2
is
/******************************************************************************
 NOME:        COMPONI_NOME_FILE
 DESCRIZIONE: Compone il nome del file relativo al documento da inviare.
 PARAMETRI:   p_cod_fiscale        Codice fiscale del contribuente
              p_anno               Anno di riferimento del documento
                                   Valorizzato solo per i ruolo, altrimenti
                                   vale 0.
              p_documento          Numero documento
                                   Se si tratta di comunicazione a ruolo,
                                   contiene il numero del ruolo; negli altri
                                   casi contiene il numero della pratica
              p_tipo_documento     Identifica il tipo di documento da trattare
                                   S - Avviso di pagamento (comunicazione a ruolo)
                                   A - Accertamento
                                   L - Liquidazione
                                   I - Accoglimento Istanza
                                   T - Sollecito
                                   F - F24 (Allegato)
                                   FI - F24 importo ridotto (Allegato)
                                   FR - F24 (Allegato a pratica rateizzata)
                                   PR - Piando di Rimborso (Allegato a pratica rateizzata)
 RITORNA:     stringa VARCHAR2     Nome del file contenente il documento da
                                   passare a GDM.
 NOTE:
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   08/03/2019  VD      Prima emissione.
******************************************************************************/
d_nome_file                                       varchar2(255);
begin
  if p_tipo_documento = 'S' then
     d_nome_file := 'COM_'||p_anno||lpad(p_documento,10,'0')||'_'||p_cod_fiscale||'.pdf';
  elsif p_tipo_documento = 'A' then
     d_nome_file := 'ACC_'||lpad(p_documento,10,'0')||'_'||p_cod_fiscale||'.pdf';
  elsif p_tipo_documento = 'L' then
     d_nome_file := 'LIQ_'||lpad(p_documento,10,'0')||'_'||p_cod_fiscale||'.pdf';
  elsif p_tipo_documento = 'I' then
     d_nome_file := 'RAI_'||lpad(p_documento,10,'0')||'_'||p_cod_fiscale||'.pdf';
  elsif p_tipo_documento = 'T' then
     d_nome_file := 'SOL_'||lpad(p_documento,10,'0')||'_'||p_cod_fiscale||'.pdf';
  else
     if nvl(substr(p_tipo_documento,2,1),' ') = 'R' then
        if substr(p_tipo_documento,1,1) = 'F' then
           d_nome_file := 'F24_R'||lpad(p_documento,10,'0')||'_'||p_cod_fiscale||'.pdf';
        else
           d_nome_file := 'PDR_R'||lpad(p_documento,10,'0')||'_'||p_cod_fiscale||'.pdf';
        end if;
     else
        if nvl(p_anno,0) = 0 then
           if nvl(substr(p_tipo_documento,2,1),' ') = 'I' then
              d_nome_file := 'F24_'||lpad(p_documento,10,'0')||'_'||p_cod_fiscale||'_RID.pdf';
           else
              d_nome_file := 'F24_'||lpad(p_documento,10,'0')||'_'||p_cod_fiscale||'.pdf';
           end if;
        else
           d_nome_file := 'F24_'||p_anno||lpad(p_documento,10,'0')||'_'||p_cod_fiscale||'.pdf';
        end if;
     end if;
  end if;
  return d_nome_file;
end;
---------------------------------------------------------------------------------------------------------
function get_tipo_comunicazione
(p_pratica           in number
,p_tipo_documento    in varchar2 default null)
return varchar2
is
/******************************************************************************
 NOME:        GET_TIPO_COMUNICAZIONE
 DESCRIZIONE: Determina il tipo comunicazione in base al documento da inviare.
 PARAMETRI:   p_cod_fiscale        Codice fiscale del contribuente
              p_anno               Anno di riferimento del documento
                                   Valorizzato solo per i ruolo, altrimenti
                                   vale 0.
              p_documento          Numero documento
                                   Se si tratta di comunicazione a ruolo,
                                   contiene il numero del ruolo; negli altri
                                   casi contiene il numero della pratica
              p_tipo_documento     Identifica il tipo di documento da trattare
                                   S - Avviso di pagamento (comunicazione a ruolo)
                                   A - Accertamento
                                   L - Liquidazione
                                   I - Accoglimento Istanza
                                   T - Sollecito
                                   F - F24 (Allegato)
                                   FP - F24 tributi minori (allegato)
                                   FT - F24 TOSAP (allegato)
                                   FI - F24 importo ridotto (Allegato)
                                   FR - F24 (Allegato a pratica rateizzata)
                                   PR - Piando di Rimborso (Allegato a pratica rateizzata)
 RITORNA:     stringa VARCHAR2     Nome del file contenente il documento da
                                   passare a GDM.
 NOTE:
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   16/10/2020  VD      Prima emissione.
******************************************************************************/
w_tipo_comunicazione                           varchar2(3);
begin
  if p_tipo_documento = 'C' then
     w_tipo_comunicazione := 'LCO';
  elsif
     p_tipo_documento = 'G' then
     w_tipo_comunicazione := 'LGE';
  elsif
     p_tipo_documento = 'S' /*or
    (p_tipo_documento = 'F' and p_anno <> 0)*/ then
     w_tipo_comunicazione := 'APA';
  elsif
     p_tipo_documento = 'D' then
     w_tipo_comunicazione := 'DEN';
  elsif
     p_tipo_documento = 'I' then
     w_tipo_comunicazione := 'RAI';
  elsif
     p_tipo_documento = 'L' then
     w_tipo_comunicazione := 'LIQ';
  elsif
     p_tipo_documento = 'T' then
     w_tipo_comunicazione := 'SOL';
  elsif
     p_tipo_documento = 'A' then
     begin
       select decode(prtr.tipo_evento,'T','ACT'
                                     ,'A','ACA'
                                     ,'ACC')
         into w_tipo_comunicazione
         from pratiche_tributo prtr
        where prtr.pratica = p_pratica;
     exception
       when others then
         w_tipo_comunicazione := null;
     end;
  else
     w_tipo_comunicazione := null;
  end if;
  return w_tipo_comunicazione;
end;
---------------------------------------------------------------------------------------------------------
function f_aggiungi_xmlcdata
(p_stringa           varchar2
) return varchar2
is
  w_stringa_output   varchar2(1000);
begin
  begin
    select xmlcdata(p_stringa).getStringVal()
      into w_stringa_output
      from dual;
  exception
    when others then
      w_stringa_output := p_stringa;
  end;
  return w_stringa_output;
end;
---------------------------------------------------------------------------------------------------------
function genera_parametri_pnd
(p_cod_fiscale       in varchar2
,p_anno              in number
,p_documento         in number
,p_tipo_tributo      in varchar2
,p_tipo_documento    in varchar2
,p_nome_file         in varchar2 default null
,p_ni_erede          in number   default null)
return sys_refcursor
is
/******************************************************************************
 NOME:        GENERA_PARAMETRI_PND
 DESCRIZIONE: Genera i parametri utili per l'invio al web service dello SmartPnd
 PARAMETRI:   p_cod_fiscale        Codice fiscale del contribuente
              p_anno               Anno di riferimento del documento
                                   Valorizzato solo per i ruolo, altrimenti
                                   vale 0.
              p_documento          Numero documento
                                   Se si tratta di comunicazione a ruolo,
                                   contiene il numero del ruolo; negli altri
                                   casi contiene il numero della pratica.
                                   Se si tratta di lettera generica il parametro
                                   e' nullo.
              p_tipo_tributo       Tipo tributo (ICI/TASI/TARSU ecc.)
              p_tipo_documento     Identifica il tipo di documento da trattare
                                   S - Avviso di pagamento (comunicazione a ruolo)
                                   A - Accertamento
                                   L - Liquidazione
                                   I - Accoglimento Istanza
                                   G - Lettera Generica
                                   C - Comunicazione di pagamento
                                   D - Denuncia
                                   F - F24 (Allegato)
                                   FI - F24 importo ridotto (Allegato)
                                   FR - F24 (Allegato a pratica rateizzata)
                                   PR - Piano di Rimborso (Allegato a pratica rateizzata)
                                   ND - Non definita
              p_login              User oracle di GDM (viene passato a null e
                                   reperito dalla tabella INSTALLAZIONE_PARAMETRI)
              p_password           Password dello user oracle di GDM (viene
                                   passato a null e reperito dalla tabella
                                   INSTALLAZIONE_PARAMETRI
              p_nome_file          facoltativo - se non presente si compone
                                   secondo le regole previste
              p_ni_erede           facoltativo - ni del soggetto erede del contribuente
 RITORNA:     stringa VARCHAR2     Il cursore contenente i parametri con cui effettuare
                                   la richiesta al web service
 NOTE:
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 003   19/09/2023  VM      #58187 - Aggiunto parametro ni_erede per ritornare info
                           riguardanti l'erede e non il contribuente
 002   26/06/2023  VM      #64450 - Aggiunti parametri per invio dettagli comunicazione
 001   09/06/2023  VM      #64450 - Duplicata la logica presente in invio_documento 
                           che genera i parametri da passare all'xml GDM
 ----  ----------  ------  ----------------------------------------------------
******************************************************************************/
d_progr                                           DOCUMENTI_CONTRIBUENTE.SEQUENZA%type;
d_se_allegato                                     varchar2(1);
d_id_documento                                    number(10);
d_nome_file                                       varchar2(255);
d_nomefile                                        varchar2(10) := 'NOME_FILE';
d_select                                          varchar2(32767);
d_dati                                            varchar2(32767);
d_testoXml                                        varchar2(4000);
d_cr                                              varchar2(200) := ' ';
d_descr_documento                                 varchar2(100);
d_cognome_nome                                    varchar2(100);
d_cognome                                         varchar2(60);
d_nome                                            varchar2(36);
d_comune_dest                                     varchar2(40);
d_provincia_dest                                  varchar2(50);
d_cap_dest                                        varchar2(10);
d_indirizzo_dest                                  varchar2(250);
d_indirizzo_pnd_dest                              varchar2(250);
d_tipo_persona_dest                               varchar2(1);
d_anno                                            number;
d_data_documento                                  varchar2(10);
d_progressivo_tr4                                      varchar2(15);
d_numero_pratica                                  varchar2(15);
d_numero_anno_tr4                                 varchar2(30);
d_tipo_tributo                                    varchar2(5);
d_tipo_comunicazione                              varchar2(5);
d_descrizione                                     varchar2(100);
d_recapito_mail                                   recapiti_soggetto.descrizione%type;
d_recapito_pec                                    recapiti_soggetto.descrizione%type;
d_label_documento                                 varchar2(20);
d_titolo_documento                                varchar2(100);
d_info_documento                                  varchar2(2000);
d_flag_firma                                      varchar2(2);
d_flag_protocollo                                 varchar2(1);
d_flag_pec                                        varchar2(1);
d_titolo_base                                     varchar2(200);
d_id_riferimento                                  number;
d_tipo_comunicazione_pnd                          varchar2(50);
d_modello_principale                              varchar2(30) := nvl(f_inpa_valore('GDM_CM'),'TRIBUTO');
d_modello_allegato                                varchar2(30) := nvl(f_inpa_valore('GDM_CM_ALL'),'DETTAGLIO_ALLEGATO');
d_modello                                         varchar2(30);
d_where                                           varchar2(4000);
d_result_fine                                     varchar2(4000);
d_progressivo_parametro                           number(10);
d_cod_fiscale_erede                               varchar2(16) := null;
ERRORE                                            EXCEPTION;
rc                                                sys_refcursor;
w_ni                                              number;
begin
     -- (VD - 08/03/2019): se il parametro nome file non è valorizzato, si compone
    --                    secondo le regole previste
    if p_nome_file is null then
       d_nome_file := tr4_to_gdm.componi_nome_file(p_cod_fiscale,p_anno,p_documento,p_tipo_documento);
    else
       d_nome_file := p_nome_file;
    end if;
    d_se_allegato := 'N';
    d_modello := d_modello_principale;
     if p_tipo_documento = 'S' then
       d_label_documento := 'Ruolo';
       d_titolo_documento := 'Comunicazione ';
    elsif p_tipo_documento = 'A' then
       d_label_documento := 'Pratica ';
       d_titolo_documento := 'Avviso di ';
    elsif p_tipo_documento = 'L' then
       d_label_documento := 'Pratica ';
       d_titolo_documento := 'Avviso di ';
    elsif p_tipo_documento = 'I' then
       d_label_documento := 'Pratica ';
       d_titolo_documento := 'Accoglimento Istanza Rateazione ';
    elsif p_tipo_documento = 'T' then
       d_label_documento := 'Pratica ';
       d_titolo_documento := 'Sollecito ';
    elsif p_tipo_documento = 'G' then
       -- Si seleziona la descrizione del modello
       begin
         select initcap(descrizione)||' '
              , tipo_tributo
           into d_titolo_documento
              , d_tipo_tributo
           from modelli
          where modello = to_number(substr(d_nome_file,5,4));
       exception
         when others then
           d_titolo_documento := 'Lettera Generica ';
           d_tipo_tributo := p_tipo_tributo;
       end;
       d_label_documento := 'Lettera ';
    elsif p_tipo_documento = 'C' then
       d_label_documento := 'Comunicazione ';
       d_titolo_documento := 'Comunicazione di pagamento ';
    elsif p_tipo_documento = 'D' then
       d_label_documento := 'Denuncia ';
       d_titolo_documento := 'Denuncia ';
    elsif p_tipo_documento = 'ND' then
       d_label_documento := 'Generica ';
       d_titolo_documento := 'Generica ';
       d_tipo_tributo := p_tipo_tributo;
    else
       if nvl(substr(p_tipo_documento,2,1),' ') = 'R' then
          if substr(p_tipo_documento,1,1) = 'F' then
             d_descr_documento := 'Modello F24 precompilato';
             d_titolo_documento := 'F24 Rateazione ';
          else
             d_descr_documento := 'Piano di Rimborso';
             d_titolo_documento := 'Piano di Rimborso Rateazione ';
          end if;
       else
          d_descr_documento := 'Modello F24 precompilato';
          d_titolo_documento := 'F24 ';
          if nvl(p_anno,0) = 0 then
             if nvl(substr(p_tipo_documento,2,1),' ') = 'I' then
                d_descr_documento := d_descr_documento||' (Importo ridotto)';
                d_titolo_documento := d_titolo_documento||'(Rid.) ';
             end if;
          end if;
       end if;
       d_modello := d_modello_allegato;
       d_se_allegato := 'S';
    end if;
    d_where := 'cod_fiscale='''||p_cod_fiscale||''' and nome_file='''||d_nome_file||'''';
--dbms_output.put_line('Nome file: '||d_nome_file);
    -- l'immagine e' memorizzata in DOCUMENTI_CONTRIBUENTE
    begin
      select sequenza, id_riferimento
        into d_progr, d_id_riferimento
        from (select sequenza, id_riferimento
                from DOCUMENTI_CONTRIBUENTE t
               where t.cod_fiscale = p_cod_fiscale
                 and t.nome_file = d_nome_file
               order by sequenza)
       where rownum = 1;
    exception
      when others then
/*        raise_application_error(-20999, 'TR4_TO_GDM - Errore in select sequenza doc ('||
                                        p_cod_fiscale||': '||sqlerrm);*/
        d_result_fine := '(TR4_TO_GDM) Errore in ricerca documento '||d_nome_file||
                         ' - '||sqlerrm;
        -- raise ERRORE;
    end;
--dbms_output.put_line('Select DOCO: '||d_progr );
    --
    -- Selezione dati per composizione XML
    --
    if p_tipo_documento in ('C', 'G', 'FP', 'FT', 'ND') then
       begin
         select sogg.cognome_nome
              , sogg.cognome
              , sogg.nome
              , to_number(to_char(sysdate,'yyyy'))
              , to_char(sysdate,'dd/mm/yyyy')
              , decode(p_tipo_documento
                                       ,'C','LCO'
                                       ,'G','LGE'
                                       ,'ND','LGE'
                                       ,'')
              , f_recapito(sogg.ni,decode(p_tipo_documento
                                                          , 'G',d_tipo_tributo
                                                          , 'ND',d_tipo_tributo
                                            ,p_tipo_tributo)
                           ,2)
              , f_recapito(sogg.ni,decode(p_tipo_documento
                                                          , 'G',d_tipo_tributo
                                                          , 'ND',d_tipo_tributo                                                          
                                          ,p_tipo_tributo)
                           ,3)
              , decode(p_tipo_documento
                           ,'G',d_tipo_tributo
                           ,'ND',d_tipo_tributo
                          ,p_tipo_tributo)
              , ''
              , to_char(sysdate,'yyyy')
              , ''
           into d_cognome_nome
              , d_cognome
              , d_nome
              , d_anno
              , d_data_documento
              , d_tipo_comunicazione
              , d_recapito_mail
              , d_recapito_pec
              , d_tipo_tributo
              , d_progressivo_tr4
              , d_numero_anno_tr4
              , d_numero_pratica
           from SOGGETTI     sogg,
                CONTRIBUENTI cont
          where cont.cod_fiscale = p_cod_fiscale
            and cont.ni = sogg.ni;

          select coen.comune_dest, coen.provincia_dest, coen.cap_dest, coen.indirizzo, coen.indirizzo_pnd, coen.tipo
            into d_comune_dest, d_provincia_dest, d_cap_dest, d_indirizzo_dest, d_indirizzo_pnd_dest, d_tipo_persona_dest
            from contribuenti_ente coen
           where coen.cod_fiscale = p_cod_fiscale
             and coen.tipo_tributo = p_tipo_tributo;
       exception
         when others then
           --raise_application_error(-20999, 'TR4_TO_GDM - Errore in select dati comunicazione: '||sqlerrm);
           d_result_fine := '(TR4_TO_GDM) Errore in selezione informazioni lettera '||
                            p_cod_fiscale||' - '||sqlerrm;
           raise ERRORE;
       end;
    elsif p_tipo_documento = 'S' or
      (p_tipo_documento = 'F' and p_anno <> 0) then
       begin
         select sogg.cognome_nome
              , sogg.cognome
              , sogg.nome
              , p_anno
              , to_char(ruol.data_emissione,'dd/mm/yyyy')
              , 'APA'
              , f_recapito(sogg.ni,p_tipo_tributo,2)
              , f_recapito(sogg.ni,p_tipo_tributo,3)
              , p_tipo_tributo
              , d_titolo_documento||'Ruolo '||
                decode(ruol.tipo_ruolo,1,'Principale ','Suppletivo ')||
                decode(nvl(tipo_emissione,'T'),'A','Acconto ','S','Saldo ','T','Totale ',null)||
                f_descrizione_titr(ruol.tipo_tributo,ruol.anno_ruolo)||
                ' n. '||ruol.ruolo||'/'||ruol.anno_ruolo
              , ruol.ruolo
              , p_anno
              , ruol.ruolo
           into d_cognome_nome
              , d_cognome
              , d_nome
              , d_anno
              , d_data_documento
              , d_tipo_comunicazione
              , d_recapito_mail
              , d_recapito_pec
              , d_tipo_tributo
              , d_titolo_documento
              , d_progressivo_tr4
              , d_numero_anno_tr4
              , d_numero_pratica
           from SOGGETTI     sogg,
                CONTRIBUENTI cont,
                RUOLI        ruol
          where ruol.ruolo = p_documento
            and cont.cod_fiscale = p_cod_fiscale
            and cont.ni = sogg.ni;


          select coen.comune_dest, coen.provincia_dest, coen.cap_dest, coen.indirizzo, coen.indirizzo_pnd, coen.tipo
            into d_comune_dest, d_provincia_dest, d_cap_dest, d_indirizzo_dest, d_indirizzo_pnd_dest, d_tipo_persona_dest
            from contribuenti_ente coen
           where coen.cod_fiscale = p_cod_fiscale
             and coen.tipo_tributo = p_tipo_tributo;
       exception
         when others then
           --raise_application_error(-20999, 'TR4_TO_GDM - Errore in select dati comunicazione: '||sqlerrm);
           d_result_fine := '(TR4_TO_GDM) Errore in selezione informazioni ruolo '||
                            p_documento||' '||p_cod_fiscale||' - '||sqlerrm;
           raise ERRORE;
       end;
    else
       begin
         select sogg.cognome_nome
              , sogg.cognome
              , sogg.nome
              , prtr.anno
              , to_char(prtr.data,'dd/mm/yyyy')
              , decode(p_tipo_documento,'A',decode(prtr.tipo_evento,'T','ACT'
                                                                   ,'A','ACA'
                                                                       ,'ACC')
                                       ,'D','DEN'
                                       ,'I','RAI'
                                       ,'L','LIQ'
                                       ,'T','SOL'
                                       ,'')
              , f_recapito(sogg.ni,p_tipo_tributo,2)
              , f_recapito(sogg.ni,p_tipo_tributo,3)
              , prtr.tipo_tributo
              , d_titolo_documento||
                decode(prtr.tipo_pratica||p_tipo_documento,'DF','Denuncia ','')||
                decode(prtr.tipo_pratica,'A','Accertamento '||decode(prtr.tipo_evento,'A','Auto '
                                                                    ,'T','Totale '
                                                                    ,'')
                                        ,'L','Liquidazione '
                                        ,'T','Sollecito '
                                        ,'')||
                f_descrizione_titr(prtr.tipo_tributo,prtr.anno)||' n. '||
                decode(prtr.tipo_pratica,'D',prtr.pratica,prtr.numero)||'/'||prtr.anno||
                decode(p_tipo_documento,'I',''
                                       ,'FR',''
                                       ,'PR',''
                                            ,' del '||to_char(prtr.data,'dd/mm/yyyy')||
                decode(prtr.data_notifica,null,'',' Not. il '||to_char(prtr.data_notifica,'dd/mm/yyyy')))
              , prtr.pratica
              , decode(prtr.numero,'',to_char(prtr.anno),'n. '||prtr.numero||'/'||to_char(prtr.anno))
              , prtr.numero
              , sogg.ni
              , decode(p_ni_erede, null, null, nvl(cont.cod_fiscale, sogg.cod_fiscale))
           into d_cognome_nome
              , d_cognome
              , d_nome
              , d_anno
              , d_data_documento
              , d_tipo_comunicazione
              , d_recapito_mail
              , d_recapito_pec
              , d_tipo_tributo
              , d_titolo_documento
              , d_progressivo_tr4
              , d_numero_anno_tr4
              , d_numero_pratica
              , w_ni
              , d_cod_fiscale_erede
           from SOGGETTI         sogg,
                CONTRIBUENTI     cont,
                PRATICHE_TRIBUTO prtr
          where prtr.pratica = p_documento
            and cont.ni(+) = sogg.ni
            and ((p_ni_erede is null and cont.cod_fiscale = p_cod_fiscale) or
               (p_ni_erede is not null and sogg.ni = p_ni_erede));

          stampa_common.delete_ni_erede_principale;
          if (p_ni_erede is not null) then
                    d_progressivo_parametro := stampa_common.set_ni_erede_principale(p_ni_erede);
          end if;

          select sopr.comune_dest, sopr.provincia_dest, sopr.cap_dest, sopr.indirizzo, 
                 decode(p_ni_erede, null, sopr.indirizzo_pnd, sopr.indirizzo_erede_pnd) indirizzo_pnd, 
                 sopr.tipo
            into d_comune_dest, d_provincia_dest, d_cap_dest, d_indirizzo_dest, d_indirizzo_pnd_dest, d_tipo_persona_dest
            from soggetti_pratica sopr
           where sopr.pratica = p_documento;
             
          stampa_common.delete_ni_erede_principale;
       exception
         when others then
           --raise_application_error(-20999, 'TR4_TO_GDM - Errore in select dati comunicazione: '||sqlerrm);
           d_result_fine := '(TR4_TO_GDM) Errore in selezione informazioni pratica '||
                            p_documento||' '||p_cod_fiscale||' - '||sqlerrm;
           raise ERRORE;
       end;
    end if;
    --
    -- selezione e controllo dei parametri per tipo comunicazione
    --
    begin
      select decode(flag_firma,null,null,'N','NF','S','DF')
           , flag_protocollo
           , flag_pec
           , titolo_documento
           , descrizione || ' ' || f_descrizione_titr(d_tipo_tributo, d_anno)
        into d_flag_firma
           , d_flag_protocollo
           , d_flag_pec
           , d_titolo_base
           , d_descrizione
        from comunicazione_parametri
       -- (VD - 10/07/2019): per l'accoglimento istanza rateazione si utilizza il tipo
       --                    tributo passato come parametro (TRASV), per gli altri
       --                    documenti si utilizza il tipo tributo selezionato
       where tipo_tributo = decode(p_tipo_documento,'I',p_tipo_tributo,d_tipo_tributo)
         and tipo_comunicazione = d_tipo_comunicazione;
    exception
      when others then
        d_flag_firma := 'NF';
        d_flag_protocollo := 'N';
        d_flag_pec := 'N';
    end;
    --

    --
    -- Selezione dell'identificativo di riferimento da apposita sequence
    --
    if d_id_riferimento is null then
       begin
         select idrif_sq.nextval
           into d_id_riferimento
           from dual;
       exception
         when others then
           --raise_application_error(-20999, 'TR4_TO_GDM - Errore in select dati: '||sqlerrm);
         d_result_fine := '(TR4_TO_GDM) Errore in select id. riferimento '||sqlerrm;
         raise ERRORE;
       end;
    end if;
    --
    begin
      select tipo_comunicazione_pnd
        into d_tipo_comunicazione_pnd
        from dettagli_comunicazione deco
      -- (VD - 10/07/2019): per l'accoglimento istanza rateazione si utilizza il tipo
      --                    tributo passato come parametro (TRASV), per gli altri
      --                    documenti si utilizza il tipo tributo selezionato
       where tipo_tributo = decode(p_tipo_documento, 'I', p_tipo_tributo, d_tipo_tributo)
         and tipo_comunicazione = d_tipo_comunicazione;
    exception
      when others then
        d_tipo_comunicazione_pnd := '';
    end;
    --

    open rc for select 'STATO_FIRMA' nome, d_flag_firma valore
                  from dual
                union
                select 'DA_PROTOCOLLARE' nome, d_flag_protocollo valore
                  from dual
                union
                select 'COGNOME_NOME' nome, d_cognome_nome valore
                  from dual
                union
                select 'COGNOME' nome, d_cognome valore
                  from dual
                union
                select 'NOME' nome, d_nome valore
                  from dual
                union
                select 'CODICE_FISCALE' nome, nvl(d_cod_fiscale_erede, p_cod_fiscale) valore
                  from dual
                union
                select 'TIPO_TRIBUTO' nome, d_tipo_tributo valore
                  from dual
                union
                select 'ANNO_TR4' nome, to_char(d_anno) valore
                  from dual
                union
                select 'PROGRESSIVO_TR4' nome, d_progressivo_tr4 valore
                  from dual
                union
                select 'NUMERO_ANNO_TR4' nome, d_numero_anno_tr4 valore
                  from dual
                union
                select 'DATA_PRATICA' nome, d_data_documento valore
                  from dual
                union
                select 'NUMERO_PRATICA' nome, to_char(d_numero_pratica) valore
                  from dual
                union
                select 'TIPO_PRATICA' nome, p_tipo_documento valore
                  from dual
                union
                select 'LABEL_PRATICA' nome, d_label_documento valore
                  from dual
                union
                select 'STATO_DOC' nome, 'DA_ELABORARE' valore
                  from dual
                union
                select 'STATO_INVIO' nome, 'DA_INVIARE' valore
                  from dual
                union
                select 'PEC_DESTINAZIONE' nome, d_recapito_pec valore
                  from dual
                union
                select 'EMAIL_DESTINAZIONE' nome, d_recapito_mail valore
                  from dual
                union
                select 'TIPO_COMUNICAZIONE' nome, d_tipo_comunicazione valore
                  from dual
                union
                select 'IDRIF' nome, to_char(d_id_riferimento) valore
                  from dual
                union
                select 'TIPO_TRIBUTO_DETTAGLIO' nome,
                       f_descrizione_titr(d_tipo_tributo, d_anno) valore
                  from dual
                union
                select 'OGGETTO' nome, nvl(d_titolo_base, d_titolo_documento) valore
                  from dual
                union
                select 'OGGETTO_STANDARD' nome, d_titolo_documento valore
                  from dual
                union
                select 'TITOLO_DOCUMENTO' nome,
                      nvl(d_titolo_base,d_titolo_documento) valore
                  from dual
                union
                select 'COMUNE_DEST' nome,
                      d_comune_dest valore
                  from dual
                union
                select 'PROVINCIA_DEST' nome,
                      d_provincia_dest valore
                  from dual
                union
                select 'CAP_DEST' nome,
                      d_cap_dest valore
                  from dual
                union
                select 'INDIRIZZO_DEST' nome,
                      d_indirizzo_dest valore
                  from dual
                union
                select 'INDIRIZZO_PND_DEST' nome,
                      d_indirizzo_pnd_dest valore
                  from dual
                union
                select 'TIPO_PERSONA_DEST' nome,
                      d_tipo_persona_dest valore
                  from dual
                union
                select 'DESCRIZIONE' nome,
                      d_descrizione valore
                  from dual
                  ;
    --
    return rc;
    --
exception
    when ERRORE then
      open rc for select 'ERRORE' nome, d_result_fine valore from dual;
      --
      return rc;
      --
end;
---------------------------------------------------------------------------------------------------------
function invio_documento
(p_cod_fiscale       in varchar2
,p_anno              in number
,p_documento         in number
,p_tipo_tributo      in varchar2
,p_tipo_documento    in varchar2
,p_login             in varchar2
,p_password          in varchar2
,p_nome_file         in varchar2 default null)
return varchar2
is
/******************************************************************************
 NOME:        INVIO_DOCUMENTO
 DESCRIZIONE: Lancia il webservice per passare il documento a GDM.
 PARAMETRI:   p_cod_fiscale        Codice fiscale del contribuente
              p_anno               Anno di riferimento del documento
                                   Valorizzato solo per i ruolo, altrimenti
                                   vale 0.
              p_documento          Numero documento
                                   Se si tratta di comunicazione a ruolo,
                                   contiene il numero del ruolo; negli altri
                                   casi contiene il numero della pratica.
                                   Se si tratta di lettera generica il parametro
                                   e' nullo.
              p_tipo_tributo       Tipo tributo (ICI/TASI/TARSU ecc.)
              p_tipo_documento     Identifica il tipo di documento da trattare
                                   S - Avviso di pagamento (comunicazione a ruolo)
                                   A - Accertamento
                                   L - Liquidazione
                                   I - Accoglimento Istanza
                                   G - Lettera Generica
                                   C - Comunicazione di pagamento
                                   D - Denuncia
                                   F - F24 (Allegato)
                                   FI - F24 importo ridotto (Allegato)
                                   FR - F24 (Allegato a pratica rateizzata)
                                   PR - Piano di Rimborso (Allegato a pratica rateizzata)
              p_login              User oracle di GDM (viene passato a null e
                                   reperito dalla tabella INSTALLAZIONE_PARAMETRI)
              p_password           Password dello user oracle di GDM (viene
                                   passato a null e reperito dalla tabella
                                   INSTALLAZIONE_PARAMETRI
              p_nome_file          facoltativo - se non presente si compone
                                   secondo le regole previste
 RITORNA:     stringa VARCHAR2     Se il webservice e' andato a buon fine,
                                   contiene l'identificativo numerico del
                                   documento creato in GDM.
                                   In caso contrario contiene il messaggio di
                                   errore.
 NOTE:
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 005   10/05/2019  VD      Aggiunta gestione nuovi documenti di tipo
                           'C' - Comunicazione di pagamento
                           'D' - Denuncia
 004   08/03/2019  VD      Aggiunto parametro nome file (facoltativo).
 003   15/02/2019  VD      Gestita presenza del carattere '&' nei campi
                           descrittivi del documento. Sostituito con 'e'.
 002   30/01/2019  VD      Aggiunta gestione allegato F24 a importo ridotto.
 001   19/11/2018  VD      Aggiunta gestione accoglimento istanza e relativi
                           allegati (F24 e piano di rimborso).
******************************************************************************/
d_progr                                           DOCUMENTI_CONTRIBUENTE.SEQUENZA%type;
d_se_allegato                                     varchar2(1);
d_id_documento                                    number(10);
d_nome_file                                       varchar2(255);
d_nomefile                                        varchar2(10) := 'NOME_FILE';
d_select                                          varchar2(32767);
d_dati                                            varchar2(32767);
d_testoXml                                        varchar2(4000);
d_cr                                              varchar2(200) := ' ';
d_descr_documento                                 varchar2(100);
d_cognome_nome                                    varchar2(100);
d_cognome                                         varchar2(60);
d_nome                                            varchar2(36);
d_anno                                            number;
d_data_documento                                  varchar2(10);
d_numero_tr4                                      varchar2(15);
d_numero_anno_tr4                                 varchar2(30);
d_tipo_tributo                                    varchar2(5);
d_tipo_comunicazione                              varchar2(5);
d_recapito_mail                                   recapiti_soggetto.descrizione%type;
d_recapito_pec                                    recapiti_soggetto.descrizione%type;
d_label_documento                                 varchar2(20);
d_titolo_documento                                varchar2(100);
d_info_documento                                  varchar2(2000);
d_flag_firma                                      varchar2(2);
d_flag_protocollo                                 varchar2(1);
d_flag_pec                                        varchar2(1);
d_titolo_base                                     varchar2(200);
d_id_riferimento                                  number;
d_conn_jndi                                       varchar2(50) := nvl(f_inpa_valore('GDM_JNDI'),'jdbc/tr4');
d_area                                            varchar2(30) := nvl(f_inpa_valore('GDM_AREA'),'TRIBUTI');
d_modello_principale                              varchar2(30) := nvl(f_inpa_valore('GDM_CM'),'TRIBUTO');
d_modello_allegato                                varchar2(30) := nvl(f_inpa_valore('GDM_CM_ALL'),'DETTAGLIO_ALLEGATO');
d_modello                                         varchar2(30);
d_tabella                                         varchar2(100) := 'DOCUMENTI_CONTRIBUENTE';
d_campo_testo                                     varchar2(100) := 'DOCUMENTO';
d_where                                           varchar2(4000);
d_result                                          varchar2(4000);
d_result_fine                                     varchar2(4000);
ERRORE                                            EXCEPTION;
begin
     -- (VD - 08/03/2019): se il parametro nome file non è valorizzato, si compone
    --                    secondo le regole previste
    if p_nome_file is null then
       d_nome_file := tr4_to_gdm.componi_nome_file(p_cod_fiscale,p_anno,p_documento,p_tipo_documento);
    else
       d_nome_file := p_nome_file;
    end if;
    d_se_allegato := 'N';
    d_modello := d_modello_principale;
     if p_tipo_documento = 'S' then
       d_label_documento := 'Ruolo n.';
       d_titolo_documento := 'Comunicazione ';
    elsif p_tipo_documento = 'A' then
       d_label_documento := 'Pratica ';
       d_titolo_documento := 'Avv. ';
    elsif p_tipo_documento = 'L' then
       d_label_documento := 'Pratica ';
       d_titolo_documento := 'Avv. ';
    elsif p_tipo_documento = 'I' then
       d_label_documento := 'Pratica ';
       d_titolo_documento := 'Accoglimento Istanza Rateazione ';
    elsif p_tipo_documento = 'T' then
       d_label_documento := 'Pratica ';
       d_titolo_documento := 'Sollecito ';
    elsif p_tipo_documento = 'G' then
       -- Si seleziona la descrizione del modello
       begin
         select initcap(descrizione)||' '
              , tipo_tributo
           into d_titolo_documento
              , d_tipo_tributo
           from modelli
          where modello = to_number(substr(d_nome_file,5,4));
       exception
         when others then
           d_titolo_documento := 'Lettera Generica ';
           d_tipo_tributo := p_tipo_tributo;
       end;
       d_label_documento := 'Lettera ';
    elsif p_tipo_documento = 'C' then
       d_label_documento := 'Comunicazione ';
       d_titolo_documento := 'Comunicazione di pagamento ';
    elsif p_tipo_documento = 'D' then
       d_label_documento := 'Denuncia ';
       d_titolo_documento := 'Denuncia ';
    else
       if nvl(substr(p_tipo_documento,2,1),' ') = 'R' then
          if substr(p_tipo_documento,1,1) = 'F' then
             d_descr_documento := 'Modello F24 precompilato';
             d_titolo_documento := 'F24 Rateazione ';
          else
             d_descr_documento := 'Piano di Rimborso';
             d_titolo_documento := 'Piano di Rimborso Rateazione ';
          end if;
       else
          d_descr_documento := 'Modello F24 precompilato';
          d_titolo_documento := 'F24 ';
          if nvl(p_anno,0) = 0 then
             if nvl(substr(p_tipo_documento,2,1),' ') = 'I' then
                d_descr_documento := d_descr_documento||' (Importo ridotto)';
                d_titolo_documento := d_titolo_documento||'(Rid.) ';
             end if;
          end if;
       end if;
       d_modello := d_modello_allegato;
       d_se_allegato := 'S';
    end if;
--dbms_output.put_line('Nome file: '||d_nome_file);
    -- l'immagine e' memorizzata in DOCUMENTI_CONTRIBUENTE
    begin
      select sequenza, id_riferimento
        into d_progr, d_id_riferimento
        from (select sequenza, id_riferimento
                from DOCUMENTI_CONTRIBUENTE t
               where t.cod_fiscale = p_cod_fiscale
                 and t.nome_file = d_nome_file
               order by sequenza desc)
       where rownum = 1;

    d_where := 'cod_fiscale='''||p_cod_fiscale||''' and nome_file='''||d_nome_file||''''||' and sequenza='||d_progr;

    exception
      when others then
/*        raise_application_error(-20999, 'TR4_TO_GDM - Errore in select sequenza doc ('||
                                        p_cod_fiscale||': '||sqlerrm);*/
        d_result_fine := '(TR4_TO_GDM) Errore in ricerca documento '||d_nome_file||
                         ' - '||sqlerrm;
        return d_result_fine;
    end;
--dbms_output.put_line('Select DOCO: '||d_progr );
    --
    -- Selezione dati per composizione XML
    --
    if p_tipo_documento in ('C', 'G', 'FP', 'FT') then
       begin
         select sogg.cognome_nome
              , sogg.cognome
              , sogg.nome
              , to_number(to_char(sysdate,'yyyy'))
              , to_char(sysdate,'dd/mm/yyyy')
              , decode(p_tipo_documento,'C','LCO'
                                       ,'G','LGE'
                                       ,'')
              -- (VD - 10/07/2019): se lettera generica (tipo = 'G'), si passa al documentale
              --                    il tipo tributo presente nel modello, altrimenti il tipo
              --                    tributo passato come parametro
              , f_recapito(sogg.ni,decode(p_tipo_documento,'G',d_tipo_tributo,p_tipo_tributo),3)
              , decode(p_tipo_documento,'G',d_tipo_tributo,p_tipo_tributo)
              , ''
              , to_char(sysdate,'yyyy')
           into d_cognome_nome
              , d_cognome
              , d_nome
              , d_anno
              , d_data_documento
              , d_tipo_comunicazione
              , d_recapito_pec
              , d_tipo_tributo
              , d_numero_tr4
              , d_numero_anno_tr4
           from SOGGETTI     sogg,
                CONTRIBUENTI cont
          where cont.cod_fiscale = p_cod_fiscale
            and cont.ni = sogg.ni;
       exception
         when others then
           --raise_application_error(-20999, 'TR4_TO_GDM - Errore in select dati comunicazione: '||sqlerrm);
           d_result_fine := '(TR4_TO_GDM) Errore in selezione informazioni lettera '||
                            p_cod_fiscale||' - '||sqlerrm;
           return d_result_fine;
       end;
    elsif p_tipo_documento = 'S' or
      (p_tipo_documento = 'F' and p_anno <> 0) then
       begin
         select sogg.cognome_nome
              , sogg.cognome
              , sogg.nome
              , p_anno
              , to_char(ruol.data_emissione,'dd/mm/yyyy')
              , 'APA'
--              , f_recapito(sogg.ni,p_tipo_tributo,2)
              , f_recapito(sogg.ni,p_tipo_tributo,3)
              , p_tipo_tributo
              , d_titolo_documento||'Ruolo '||
                decode(ruol.tipo_ruolo,1,'Principale ','Suppletivo ')||
                decode(nvl(tipo_emissione,'T'),'A','Acconto ','S','Saldo ','T','Totale ',null)||
                f_descrizione_titr(ruol.tipo_tributo,ruol.anno_ruolo)||
                ' n. '||ruol.ruolo||'/'||ruol.anno_ruolo
              , ''
              , p_anno
           into d_cognome_nome
              , d_cognome
              , d_nome
              , d_anno
              , d_data_documento
              , d_tipo_comunicazione
--              , d_recapito_mail
              , d_recapito_pec
              , d_tipo_tributo
              , d_titolo_documento
              , d_numero_tr4
              , d_numero_anno_tr4
           from SOGGETTI     sogg,
                CONTRIBUENTI cont,
                RUOLI        ruol
          where ruol.ruolo = p_documento
            and cont.cod_fiscale = p_cod_fiscale
            and cont.ni = sogg.ni;
       exception
         when others then
           --raise_application_error(-20999, 'TR4_TO_GDM - Errore in select dati comunicazione: '||sqlerrm);
           d_result_fine := '(TR4_TO_GDM) Errore in selezione informazioni ruolo '||
                            p_documento||' '||p_cod_fiscale||' - '||sqlerrm;
           return d_result_fine;
       end;
    else
       begin
         select sogg.cognome_nome
              , sogg.cognome
              , sogg.nome
              , prtr.anno
              , to_char(prtr.data,'dd/mm/yyyy')
              , decode(p_tipo_documento,'A',decode(prtr.tipo_evento,'T','ACT'
                                                                   ,'A','ACA'
                                                                       ,'ACC')
                                       ,'D','DEN'
                                       ,'I','RAI'
                                       ,'L','LIQ'
                                       ,'T','SOL'
                                       ,'')
--              , f_recapito(sogg.ni,p_tipo_tributo,2)
              , f_recapito(sogg.ni,p_tipo_tributo,3)
              , prtr.tipo_tributo
              , d_titolo_documento||
                decode(prtr.tipo_pratica||p_tipo_documento,'DF','Denuncia ','')||
                decode(prtr.tipo_pratica,'A','Acc. '||decode(prtr.tipo_evento,'A','Auto '
                                                                    ,'T','Totale '
                                                                    ,'')
                                        ,'L','Liq. '
                                        ,'T','Sol. '
                                        ,'')||
                f_descrizione_titr(prtr.tipo_tributo,prtr.anno)||' n. '||
                decode(prtr.tipo_pratica,'D',prtr.pratica,prtr.numero)||'/'||prtr.anno||
                decode(p_tipo_documento,'I',''
                                       ,'FR',''
                                       ,'PR',''
                                            ,' del '||to_char(prtr.data,'dd/mm/yyyy')||
                decode(prtr.data_notifica,null,'',' Not. il '||to_char(prtr.data_notifica,'dd/mm/yyyy')))
              , prtr.numero
              , decode(prtr.numero,'',to_char(prtr.anno),'n. '||prtr.numero||'/'||to_char(prtr.anno))
           into d_cognome_nome
              , d_cognome
              , d_nome
              , d_anno
              , d_data_documento
              , d_tipo_comunicazione
--              , d_recapito_mail
              , d_recapito_pec
              , d_tipo_tributo
              , d_titolo_documento
              , d_numero_tr4
              , d_numero_anno_tr4
           from SOGGETTI         sogg,
                CONTRIBUENTI     cont,
                PRATICHE_TRIBUTO prtr
          where prtr.pratica = p_documento
            and cont.cod_fiscale = p_cod_fiscale
            and cont.ni = sogg.ni;
       exception
         when others then
           --raise_application_error(-20999, 'TR4_TO_GDM - Errore in select dati comunicazione: '||sqlerrm);
           d_result_fine := '(TR4_TO_GDM) Errore in selezione informazioni pratica '||
                            p_documento||' '||p_cod_fiscale||' - '||sqlerrm;
           return d_result_fine;
       end;
    end if;
    --
    -- selezione e controllo dei parametri per tipo comunicazione
    --
    begin
      select decode(nvl(flag_firma,'N'),'N','NF','DF')
           , nvl(flag_protocollo,'N')
           , nvl(flag_pec,'N')
           , titolo_documento
        into d_flag_firma
           , d_flag_protocollo
           , d_flag_pec
           , d_titolo_base
        from comunicazione_parametri
       -- (VD - 10/07/2019): per l'accoglimento istanza rateazione si utilizza il tipo
       --                    tributo passato come parametro (TRASV), per gli altri
       --                    documenti si utilizza il tipo tributo selezionato
       where tipo_tributo = decode(p_tipo_documento,'I',p_tipo_tributo,d_tipo_tributo)
         and tipo_comunicazione = d_tipo_comunicazione;
    exception
      when others then
        d_flag_firma := 'NF';
        d_flag_protocollo := 'N';
        d_flag_pec := 'N';
    end;
    --
    if d_flag_pec = 'S' and
       d_recapito_pec is null then
       d_result_fine := '(TR4_TO_GDM) PEC non presente per il contribuente '||p_cod_fiscale;
       return d_result_fine;
    end if;
    --
    -- Selezione dell'identificativo di riferimento da apposita sequence
    --
    if d_id_riferimento is null then
       begin
         select idrif_sq.nextval
           into d_id_riferimento
           from dual;
       exception
         when others then
           --raise_application_error(-20999, 'TR4_TO_GDM - Errore in select dati: '||sqlerrm);
         d_result_fine := '(TR4_TO_GDM) Errore in select id. riferimento '||sqlerrm;
         return d_result_fine;
       end;
    end if;
    --
    -- Composizione xml per web service
    --
    if d_se_allegato = 'N' then
       d_select := 'select ''STATO_FIRMA'' nome'||
                           ','''||d_flag_firma||''' valore'||
                           ' from dual union '||
                   'select ''DA_PROTOCOLLARE'' nome'||
                           ','''||d_flag_protocollo||''' valore'||
                           ' from dual union '||
                   'select ''COGNOME_NOME'' nome'||
                           ','''||replace(replace(replace(d_cognome_nome,'&','e'),'''',''''''),'"','''''')||''' valore'||
                           ' from dual union '||
                   'select ''COGNOME'' nome'||
                           ','''||replace(replace(replace(d_cognome,'&','e'),'''',''''''),'"','''''')||''' valore'||
                           ' from dual union '||
                   'select ''NOME'' nome'||
                           ','''||replace(replace(replace(d_nome,'&','e'),'''',''''''),'"','''''')||''' valore'||
                           ' from dual union '||
                   'select ''CODICE_FISCALE'' nome'||
                           ','''||p_cod_fiscale||''' valore'||
                          ' from dual union '||
                   'select ''TIPO_TRIBUTO'' nome'||
                           ','''||d_tipo_tributo||''' valore'||
                           ' from dual union '||
                   'select ''ANNO_TR4'' nome'||
                           ','''||d_anno||''' valore'||
                           ' from dual union '||
                   'select ''NUMERO_TR4'' nome'||
                           ','''||d_numero_tr4||''' valore'||
                           ' from dual union '||
                   'select ''NUMERO_ANNO_TR4'' nome'||
                           ','''||d_numero_anno_tr4||''' valore'||
                           ' from dual union '||
                   'select ''DATA_PRATICA'' nome'||
                           ','''||d_data_documento||''' valore'||
                           ' from dual union '||
                   'select ''NUMERO_PRATICA'' nome'||
                          ','''||p_documento||''' valore'||
                           ' from dual union '||
                   'select ''TIPO_PRATICA'' nome'||
                           ','''||p_tipo_documento||''' valore'||
                           ' from dual union '||
                   'select ''LABEL_PRATICA'' nome'||
                           ','''||d_label_documento||''' valore'||
                           ' from dual union '||
                   'select ''STATO_DOC'' nome'||
                           ',''DA_ELABORARE'' valore'||
                           ' from dual union '||
                   'select ''STATO_INVIO'' nome'||
                           ',''DA_INVIARE'' valore'||
                           ' from dual union '||
                   'select ''PEC_DESTINAZIONE'' nome'||
                           ','''||d_recapito_pec||''' valore'||
                           ' from dual union '||
                   'select ''TIPO_COMUNICAZIONE'' nome'||
                           ','''||d_tipo_comunicazione||''' valore'||
                           ' from dual union '||
                   'select ''IDRIF'' nome'||
                           ','''||d_id_riferimento||''' valore'||
                           ' from dual union '||
                   'select ''TIPO_TRIBUTO_DETTAGLIO'' nome'||
                           ','''||f_descrizione_titr(d_tipo_tributo,d_anno)||''' valore'||
                           ' from dual union '||
                   'select ''OGGETTO'' nome'||
                           ','''||nvl(d_titolo_base,d_titolo_documento)||''' valore'||
                           ' from dual'
                           ;
    else
       d_select :=  'select ''DESCRIZIONE'' nome'||
                           ','''||d_descr_documento||''' valore'||
                           ' from dual union '||
                    'select ''IDRIF'' nome'||
                           ','''||d_id_riferimento||''' valore'||
                           ' from dual';
    end if;
    --
    begin
      d_dati := replace(get_xml(d_select),'<?xml version = ''1.0''?>','');
    exception
      when others then
        --raise_application_error(-20999,'Errore in funzione get_xml ('||p_cod_fiscale||
        --                               ') - '||sqlerrm);
        d_result_fine := '(TR4_TO_GDM) Errore in funzione get_xml ('||p_cod_fiscale||') - '||sqlerrm;
        return d_result_fine;
    end;
    begin
      d_testoxml := get_xmltesto(d_conn_jndi, d_nomefile, d_tabella, d_campo_testo, d_where);
    exception
      when others then
        --raise_application_error(-20999,'Errore in funzione get_xmltesto ('||p_cod_fiscale||
        --                               ') - '||sqlerrm);
        d_result_fine := '(TR4_TO_GDM) Errore in funzione get_xmltesto ('||p_cod_fiscale||') - '||sqlerrm;
        return d_result_fine;
    end;
/*    dbms_output.put_line('----> Testo XML');
    dbms_output.put_line(substr(d_testoxml,1,250));
    dbms_output.put_line(substr(d_testoxml,251,250));
    dbms_output.put_line(substr(d_testoxml,501,250));
    dbms_output.put_line(substr(d_testoxml,751,250));
    dbms_output.put_line(substr(d_testoxml,1001,250));
    dbms_output.put_line(substr(d_testoxml,1251,250));
    dbms_output.put_line(substr(d_testoxml,1501,250));
    dbms_output.put_line(substr(d_testoxml,1751,250));
    dbms_output.put_line(substr(d_testoxml,2001,250));
    dbms_output.put_line(substr(d_testoxml,2251,250));
    dbms_output.put_line(substr(d_testoxml,2501,250));
    dbms_output.put_line(substr(d_testoxml,2751,250));
    dbms_output.put_line(substr(d_testoxml,2301,250));
    dbms_output.put_line('----> Fine Testo XML'); */
   --salvo l'invio del ws nella tabella DOCUMENTI_CONTRIBUENTE
   begin
     update documenti_contribuente
        set validita_al = to_date(null),
            titolo = decode(d_titolo_documento,'F24 ',titolo,nvl(d_titolo_base,d_titolo_documento)),
            xmlsend = to_clob(d_dati),
            id_riferimento = d_id_riferimento
      where cod_fiscale = p_cod_fiscale
        and sequenza = d_progr
        and nome_file = d_nome_file
      ;
    exception
      when others then
        --raise_application_error(-20999,'Errore in update send DOCO ('||p_cod_fiscale||
        --                               ') - '||sqlerrm);
        d_result_fine := '(TR4_TO_GDM) Errore in update send DOCO ('||p_cod_fiscale||') - '||sqlerrm;
        return d_result_fine;
    end;
commit;
    -- invio comunicazione
    begin
      d_result := sendProfiloRegistra (d_area, d_modello, d_dati, d_testoxml, d_cr, p_login, p_password);
    exception
      when others then
        --raise_application_error(-20999,'Errore in funzione sendProfiloRegistra ('||
        --                               p_cod_fiscale||') - '||sqlerrm);
        d_result_fine := '(TR4_TO_GDM) Errore in funzione sendProfiloRegistra ('||p_cod_fiscale||') - '||sqlerrm;
        return d_result_fine;
    end;
/*    dbms_output.put_line('-----> sendProfiloRegistra ----');
    dbms_output.put_line(substr(d_result,1,250));
    dbms_output.put_line(substr(d_result,251,250));
    dbms_output.put_line(substr(d_result,501,250));
    dbms_output.put_line(substr(d_result,751,250));
    dbms_output.put_line(substr(d_result,1001,250));
    dbms_output.put_line(substr(d_result,1251,250));
    dbms_output.put_line(substr(d_result,1501,250));
    dbms_output.put_line(substr(d_result,1751,250));
    dbms_output.put_line(substr(d_result,2001,250));
    dbms_output.put_line(substr(d_result,2251,250));
    dbms_output.put_line(substr(d_result,2501,250));
    dbms_output.put_line(substr(d_result,2751,250));
    dbms_output.put_line(substr(d_testoxml,2301,250));
    dbms_output.put_line('-----> fine sendProfiloRegistra ----');*/
   --salvo la risposta ricevuta nella tabella DOCUMENTI_CONTRIBUENTE
   update documenti_contribuente
      set xmlreceive = to_clob(d_result)
    where cod_fiscale = p_cod_fiscale
      and sequenza = d_progr
      and nome_file = d_nome_file
    ;
   -- Commit per salvare su documenti_contribuente la risposta ricevuta dal ws
   commit;
   d_result_fine := parseProfiloRegistraResponse(d_result);
   --salvo l'id del documento generato nella tabella DOCUMENTI_CONTRIBUENTE
   if afc.is_numeric(d_result_fine) = 1 then
      update documenti_contribuente
         set id_documento_gdm = to_number(d_result_fine)
           , informazioni = 'Inv. al documentale'
           , documento = empty_blob()
       where cod_fiscale = p_cod_fiscale
         and sequenza = d_progr
         and nome_file = d_nome_file
       ;
   else
      update documenti_contribuente
         set xmlreceive = to_clob(d_result_fine)
       where cod_fiscale = p_cod_fiscale
         and sequenza = d_progr
         and nome_file = d_nome_file
       ;
        d_result_fine := '(TR4_TO_GDM) Errore in funzione sendProfiloRegistra ('||p_cod_fiscale||') - '||sqlerrm;
   end if;
   commit;
   return d_result_fine;
end;
---------------------------------------------------------------------------------------------------------
function annulla_documento_TR4
(p_id_rif_gdm  in number
) return varchar2
is
/******************************************************************************
 NOME:        ANNULLA_DOCUMENTO_TR4
 DESCRIZIONE: Annulla i riferimenti a GDM sulla tabella DOCUMENTI_CONTRIBUENTE
              (utilizzata in caso di annullamento documento da GDM, per
              consentire la ri-emissione).
 PARAMETRI:   p_id_rif_gdm         Identificativo di riferimento del documento
                                   GDM abbinato alla riga presente in
                                   DOCUMENTI_CONTRIBUENTE. Con idrif si
                                   annullano il documento principale e tutti i
                                   suoi allegati.
 RITORNA:     stringa VARCHAR2     Se l'operazione è andata a buon fine la
                                   stringa è vuota, altrimenti contiene il
                                   messaggio di errore.
 NOTE:
******************************************************************************/
  w_messaggio                      varchar2(2000) := '';
  w_righe_agg                      number;
begin
  begin
    update DOCUMENTI_CONTRIBUENTE
       set id_documento_gdm = to_number(null)
         , id_riferimento = to_number(null)
         , anno_protocollo = to_number(null)
         , numero_protocollo = to_number(null)
         , informazioni = informazioni||' - Annullato'
     where id_riferimento = p_id_rif_gdm;
    w_righe_agg := sql%rowcount;
  exception
    when others then
      w_messaggio := substr('Annulla documento: '||sqlerrm,1,2000);
  end;
--
  if w_righe_agg = 0 then
     w_messaggio := 'Non esistono documenti da annullare';
  end if;
--
  return w_messaggio;
--
end;
---------------------------------------------------------------------------------------------------------
function aggiorna_protocollo_tr4
(p_id_documento       in number
,p_anno_protocollo    in number
,p_numero_protocollo  in number
) return varchar2
is
/******************************************************************************
 NOME:        AGGIORNA_PROTOCOLLO_TR4
 DESCRIZIONE: Aggiorna i riferimenti di protocollazione del documento nella
              tabella DOCUMENTI_CONTRIBUENTE.
              Una volta protocollato, il documento non può più essere modificato.
              La funzione riporta i riferimenti del protocollo sul documento
              principale e su tutti i suoi allegati.
 PARAMETRI:   p_id_documento       Identificativo del documento GDM abbinato
                                   alla riga presente in DOCUMENTI_CONTRIBUENTE.
              p_anno_protocollo    Anno di protocollo.
              p_numero_protocollo  Numero di protocollo.
 RITORNA:     stringa VARCHAR2     Se l'operazione è andata a buon fine la
                                   stringa è vuota, altrimenti contiene il
                                   messaggio di errore.
 NOTE:
******************************************************************************/
  w_id_riferimento                 number;
  w_messaggio                      varchar2(2000) := '';
  w_righe_agg                      number;
begin
  --
  -- Si seleziona l'id. riferimento del documento da aggiornare, in modo da
  -- riportare i riferimenti al protocollo sul documento principale e sui
  -- suoi allegati
  --
  begin
    select id_riferimento
      into w_id_riferimento
      from documenti_contribuente
     where id_documento_gdm = p_id_documento;
  exception
    when others then
      w_messaggio := substr('Select id. riferimento: '||sqlerrm,1,2000);
  end;
  --
  begin
    update DOCUMENTI_CONTRIBUENTE
       set anno_protocollo = p_anno_protocollo
         , numero_protocollo = p_numero_protocollo
         , informazioni = informazioni||' - Prot. n. '||p_numero_protocollo||'/'||p_anno_protocollo
     where id_riferimento = w_id_riferimento;
    w_righe_agg := sql%rowcount;
  exception
    when others then
      w_messaggio := substr('Aggiorna rif. protocollo: '||sqlerrm,1,2000);
  end;
--
  if w_righe_agg = 0 then
     w_messaggio := 'Protocollo: Non esistono documenti da aggiornare';
  end if;
--
  return w_messaggio;
--
end;
---------------------------------------------------------------------------------------------------------
function converti_data
(p_data_input                varchar2
) return date
is
/******************************************************************************
 NOME:        CONVERTI_DATA
 DESCRIZIONE: Converte la data dal formato stringa presente in GDM al formato
              date per aggiornare la data di notifica su pratiche_tributo.
              Se la conversione fallisce restituisce null.
 PARAMETRI:   p_data_input         Data in formato stringa.
 RITORNA:     data date            Se l'operazione è andata a buon fine la
                                   data e' valorizzata, altrimenti e' nulla.
 NOTE:
******************************************************************************/
d_data_input                 varchar2(100);
d_data_output                date;
begin
  --
  -- Si eliminano eventuali virgole e timezone CEST, CET
  --
  d_data_input := rtrim(ltrim(p_data_input));
  d_data_input := replace(d_data_input,' CEST','');
  d_data_input := replace(d_data_input,' CET','');
  d_data_input := replace(d_data_input,',','');
dbms_output.put_line('Data 1: '||d_data_input);
  --
  -- si eliminano i primi 3 caratteri se contengono il nome del giorno in
  -- inglese oppure in italiano; nel caso dell'italiano, si aggiunge uno zero
  -- davanti al numero del giorno se minore di 10
  --
  if lower(substr(d_data_input,1,3)) in ('sun','mon','tue','wed','thu','fri','sat') then
     d_data_input := substr(d_data_input,5);
  elsif lower(substr(d_data_input,1,3)) in ('lun','mar','mer','gio','ven','sab','dom') then
     d_data_input := substr(d_data_input,5);
     if afc.is_number(substr(d_data_input,2,1)) = 0 then
        d_data_input := '0'||d_data_input;
     end if;
  end if;
dbms_output.put_line('Data 2: '||d_data_input);
  --
  -- Trattamento date di 10 caratteri
  --
  begin
    if length(d_data_input) = 10 then
       if length(d_data_input) - length(replace(d_data_input,'/','')) = 2 then
          if instr(d_data_input,'/',1,1) in (2,3) then
             -- Data nel formato dd/mm/yyyy
             d_data_output := to_date(lpad(d_data_input,10,'0'),'dd/mm/yyyy');
          else
             -- Data nel formato yyyy/mm/dd
             d_data_output := to_date(d_data_input,'yyyy/mm/dd');
          end if;
       else
          -- Data nel formato yyyy-mm-dd
          if length(d_data_input) - length(replace(d_data_input,'-','')) = 2 then
             d_data_output := to_date(d_data_input,'yyyy-mm-dd');
          end if;
       end if;
    else
       --
       -- Date piu' lunghe di 10 caratteri - Si elimina l'eventuale orario
       --
       if length(d_data_input) - length(replace(d_data_input,':','')) = 2 then
          d_data_input := substr(d_data_input,1,instr(d_data_input,':',1)-3)||
                          substr(d_data_input,instr(d_data_input,':',1,2)+4);
       end if;
       --
       -- Si sostituisce il mese in italiano con il mese in inglese
       -- (dove diversi)
       --
       if lower(d_data_input) like '%gen%' then
          d_data_input := replace(lower(d_data_input),'gen','jan');
       elsif
          lower(d_data_input) like '%mag%' then
          d_data_input := replace(lower(d_data_input),'mag','may');
       elsif
          lower(d_data_input) like '%giu%' then
          d_data_input := replace(lower(d_data_input),'giu','jun');
       elsif
          lower(d_data_input) like '%lug%' then
          d_data_input := replace(lower(d_data_input),'lug','jul');
       elsif
          lower(d_data_input) like '%ago%' then
          d_data_input := replace(lower(d_data_input),'ago','aug');
       elsif
          lower(d_data_input) like '%set%' then
          d_data_input := replace(lower(d_data_input),'set','sep');
       elsif
          lower(d_data_input) like '%ott%' then
          d_data_input := replace(lower(d_data_input),'ott','oct');
       elsif
          lower(d_data_input) like '%dic%' then
          d_data_input := replace(lower(d_data_input),'dic','dec');
       end if;
dbms_output.put_line('Data 3: '||d_data_input);
       if afc.is_number(substr(d_data_input,1,1)) = 1 then
          d_data_output := to_date(d_data_input,'dd mon yyyy');
       else
          d_data_output := to_date(d_data_input,'mon dd yyyy');
       end if;
dbms_output.put_line('Data 4: '||d_data_output);
    end if;
  exception
    when others then
      d_data_output := to_date(null);
  end;
--
  return d_data_output;
--
end;
---------------------------------------------------------------------------------------------------------
function aggiorna_date_tr4
(p_id_documento       in number
,p_data_invio_pec     in varchar2
,p_data_ricezione_pec in varchar2
) return varchar2
is
/******************************************************************************
 NOME:        AGGIORNA_DATE_TR4
 DESCRIZIONE: Aggiorna la data di invio PEC e la data di ricezione da parte del
              contribuente del documento nellatabella DOCUMENTI_CONTRIBUENTE.
              Una volta inviato, il documento non può più essere modificato.
              La funzione riporta le date sul documento principale e su tutti
              i suoi allegati.
 PARAMETRI:   p_id_documento       Identificativo del documento GDM abbinato
                                   alla riga presente in DOCUMENTI_CONTRIBUENTE.
              p_data_invio_pec     Data in cui il documento viene inviato al
                                   contribuente via PEC.
              p_data_ricezione_pec Data in cui il contribuente riceve il
                                   documento via PEC.
 RITORNA:     stringa VARCHAR2     Se l'operazione è andata a buon fine la
                                   stringa è vuota, altrimenti contiene il
                                   messaggio di errore.
 NOTE:
******************************************************************************/
  w_id_riferimento                 number;
  w_pratica                        number;
  w_tipo_doc                       varchar2(3);
  w_data_invio_pec                 date;
  w_data_ricezione_pec             date;
  w_messaggio                      varchar2(2000) := '';
  w_righe_agg                      number;
begin
  --
  -- Si seleziona l'id. riferimento del documento da aggiornare, in modo da
  -- riportare le date di invio/ricezione PEC sul documento principale e sui
  -- suoi allegati
  --
  begin
    select id_riferimento
         , pratica
         , substr(nome_file,1,3)
      into w_id_riferimento
         , w_pratica
         , w_tipo_doc
      from documenti_contribuente
     where id_documento_gdm = p_id_documento;
  exception
    when others then
      w_messaggio := substr('Select id. riferimento: '||sqlerrm,1,2000);
  end;
  --
  if w_pratica is not null then
     w_data_invio_pec     := converti_data(p_data_invio_pec);
     w_data_ricezione_pec := converti_data(p_data_ricezione_pec);
     dbms_output.put_line('Data invio convertita: '||w_data_invio_pec);
     dbms_output.put_line('Data ricezione convertita: '||w_data_ricezione_pec);
  end if;
  begin
    update DOCUMENTI_CONTRIBUENTE
       set data_invio_pec = p_data_invio_pec
         , data_ricezione_pec = p_data_ricezione_pec
         , informazioni = informazioni||' - Not. il '||nvl(to_char(w_data_invio_pec,'dd/mm/yyyy'),p_data_ricezione_pec)
     where id_riferimento = w_id_riferimento;
    w_righe_agg := sql%rowcount;
  exception
    when others then
      w_messaggio := substr('Aggiorna date PEC: '||sqlerrm,1,2000);
  end;
--
  if w_righe_agg = 0 then
     w_messaggio := 'Date invio/ricezione PEC: Non esistono documenti da aggiornare';
  end if;
--
-- Se il documento si riferisce ad una pratica NON rateizzata, si aggiorna la data
-- di notifica
--
  if w_pratica is not null and
     w_tipo_doc <> 'RAI' and
     w_data_invio_pec is not null and
     w_data_ricezione_pec is not null then
     --
     -- La data di notifica viene aggiornata con la data di invio della PEC
     -- solo se sono valorizzate entrambe (invio e ricezione)
     -- versione Barchi - Casalgrande
     begin
       update pratiche_tributo
          set data_notifica = w_data_invio_pec
        where pratica = w_pratica
          and data_notifica is null;
    exception
      when others then
        w_messaggio := substr('Errore in aggiornamento data notifica pratica '||
                              w_pratica||sqlerrm,1,2000);
    end;
  end if;
--
  return w_messaggio;
--
end;
---------------------------------------------------------------------------------------------------------
PROCEDURE invio_documento_old
(p_cod_fiscale       in varchar2
,p_anno_ruolo        in number
,p_ruolo             in number
,p_tipo_tributo      in varchar2
,p_utente            in varchar2
,p_gruppo_firma      in varchar2
,p_idDocument        in out number
,p_code_errore       out number
,p_descr_errore      out varchar2)
IS
d_response                                        CLOB;
d_codresp                                         number (10);
d_iderrore                                        VARCHAR2 (20);
d_descrerr                                        VARCHAR2 (2000);
d_xml                                             XMLTYPE;
d_xmlresult                                       XMLTYPE;
d_xml_clob                                        CLOB;
d_documento_blob                                  BLOB;
d_documento_clob                                  CLOB;
d_progr                                           DOCUMENTI_CONTRIBUENTE.SEQUENZA%type;
d_id_documento                                    NUMBER(10);
d_fatture_distinta                                varchar2(32000);
d_bar_code                                        varchar2(200);
d_chiave                                          varchar2(100);
d_service_url                                     varchar(200);
d_esito                                           varchar2(20);
d_messaggio_errore                                varchar2(2000);
d_utente_firmatario                               varchar2(8);
d_gruppo_notifica                                 varchar2(8);
d_nome_file                                       varchar2(255);
d_stringa_metainfo_1                              varchar2(100) := '<metaInfo xmlns="">';
d_stringa_metainfo_2                              varchar2(100) := '</metaInfo>';
ERRORE                                            EXCEPTION;
BEGIN
  BEGIN
    scambio_dati_ws.wpkg_ws_servizio := 1;
    d_service_url := scambio_dati_ws.get_service(wPKG_cod_integrazione,wPkg_Ente);
    d_nome_file := 'COM_'||p_anno_ruolo||lpad(p_ruolo,10,'0')||'_'||p_cod_fiscale||'.pdf';
--dbms_output.put_line('Nome file: '||d_nome_file);
    -- l'immagine e' memorizzata in DOCUMENTI_CONTRIBUENTE
    select sequenza
          ,documento
      into d_progr
          ,d_documento_blob
      from DOCUMENTI_CONTRIBUENTE t
     where t.cod_fiscale = p_cod_fiscale
       and t.nome_file = d_nome_file
         ;
--dbms_output.put_line('Select DOCO');
    --
    --d_documento_clob := SI4_BASE64_EXT.ENCODE(d_documento_blob);
    --dbms_output.put_line('si4_base64');
    -- elenco fatture in distinta
/*    FOR c_righe in (select distinct a.esercizio_rif
                                    ,a.articolo_rif
                                    ,a.esercizio
                                    ,a.articolo
                                from autorizzazioni a
                               where a.anno_distinta = p_anno_distinta
                                 and a.numero_distinta = p_numero_distinta
                              )
    loop
        BEGIN
          -- reperimento dell' id_documento di GDM
          select max(d.bar_code)
            into d_bar_code
            from documenti_contabilita d
           where d.esercizio = c_righe.esercizio
             and d.articolo = c_righe.articolo
           ;
           if d_bar_code is not null then
             if d_fatture_distinta is null then
                d_fatture_distinta := d_bar_code ||'#';
             else
                d_fatture_distinta := d_fatture_distinta
                                   ||d_bar_code
                                   ||'#'
                                   ;
             end if;
           end if;
        end;
    end loop;  */
/*    select nvl(max(utente),'FE_ENTE')
      into d_gruppo_notifica
      from ad4_utenti
     where utente = 'GDIST'
    ;*/
    select d_stringa_metainfo_1||
           xmlelement("codice",'STATO_FIRMA')||
           xmlelement("valore",'DF')||
           d_stringa_metainfo_2||
           d_stringa_metainfo_1||
           xmlelement("codice",'COGNOME_NOME')||
           xmlelement("valore",replace(sogg.cognome_nome,'/',' '))||
           d_stringa_metainfo_2||
           d_stringa_metainfo_1||
           xmlelement("codice",'CODICE_FISCALE')||
           xmlelement("valore",p_cod_fiscale)||
           d_stringa_metainfo_2||
           d_stringa_metainfo_1||
           xmlelement("codice",'TIPO_TRIBUTO')||
           xmlelement("valore",p_tipo_tributo)||
           d_stringa_metainfo_2||
           d_stringa_metainfo_1||
           xmlelement("codice",'ANNO_TR4')||
           xmlelement("valore",p_anno_ruolo)||
           d_stringa_metainfo_2||
           d_stringa_metainfo_1||
           xmlelement("codice",'DATA_PRATICA')||
           xmlelement("valore",to_char(ruol.data_emissione,'dd/mm/yyyy'))||
           d_stringa_metainfo_2||
           d_stringa_metainfo_1||
           xmlelement("codice",'NUMERO_PRATICA')||
           xmlelement("valore",p_ruolo)||
           d_stringa_metainfo_2||
           d_stringa_metainfo_1||
           xmlelement("codice",'TIPO_PRATICA')||
           xmlelement("valore",'A')||
           d_stringa_metainfo_2||
           d_stringa_metainfo_1||
           xmlelement("codice",'STATO_DOC')||
           xmlelement("valore",'DA_ELABORARE')||
           d_stringa_metainfo_2||
           d_stringa_metainfo_1||
           xmlelement("codice",'MAIL_DESTINAZIONE')||
           xmlelement("valore",f_recapito(sogg.ni,p_tipo_tributo,2))||
           d_stringa_metainfo_2||
           d_stringa_metainfo_1||
           xmlelement("codice",'PEC_DESTINAZIONE')||
           xmlelement("valore",f_recapito(sogg.ni,p_tipo_tributo,3))||
           d_stringa_metainfo_2
      into d_xml_clob
      from SOGGETTI     sogg,
           CONTRIBUENTI cont,
           RUOLI        ruol
     where ruol.ruolo = p_ruolo
       and cont.cod_fiscale = p_cod_fiscale
       and cont.ni = sogg.ni
       and (f_recapito(sogg.ni,p_tipo_tributo,2) is not null or
            f_recapito(sogg.ni,p_tipo_tributo,3) is not null)
        ;
--dbms_output.put_line('Composto CLOB');
    -- invio distinta
    --d_xml_clob := d_xml.getClobVal() ;
    d_xml_clob := '<ser:createDocument><area xmlns="">TRIBUTI</area><model xmlns="">TRIBUTO</model>'
                || d_xml_clob
                ||'<acls xmlns="">
            <accesso>S</accesso>
            <tipoCompetenza>L</tipoCompetenza>
            <utenteGruppo>GDM</utenteGruppo>
         </acls>
         <acls xmlns="">
            <accesso>S</accesso>
            <tipoCompetenza>U</tipoCompetenza>
            <utenteGruppo>ADMINS</utenteGruppo>
         </acls>
         <utenteApplicativo>GDM</utenteApplicativo>
      </ser:createDocument>'
                ;
--dbms_output.put_line('Finito CLOB');
   --salvo l'invio del ws nella tabella DOCUMENTI_CONTRIBUENTE
   update documenti_contribuente
      set xmlsend = d_xml_clob
    where cod_fiscale = p_cod_fiscale
      and sequenza = d_progr
      and nome_file = d_nome_file
    ;
--commit;
--dbms_output.put_line('Update DOCO 1');
--dbms_output.put_line('d_service_url: '||d_service_url);
   d_xmlresult := ws_finmatica_request(d_service_url,d_xml_clob,wPKG_cod_integrazione,600,'GDM');
--dbms_output.put_line('lancio ws');
   --salvo la risposta ricevuta nella tabella DOCUMENTI_CONTRIBUENTE
   update documenti_contribuente
      set xmlreceive = d_xmlresult.getClobVal()
    where cod_fiscale = p_cod_fiscale
      and sequenza = d_progr
      and nome_file = d_nome_file
    ;
--dbms_output.put_line('Update DOCO 2');
    commit;
    IF d_xmlresult.EXISTSNODE ('//errstr') = 0 THEN
--dbms_output.put_line('EXISTSNODE: '||d_xmlresult.EXISTSNODE ('//errstr'));
       SELECT d_xmlresult.EXTRACT
                 ('//result/text()'
                 , 'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"'
                 ).getstringval ()
            , d_xmlresult.EXTRACT
                 ('//idDocument/text()'
                 , 'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"'
                 ).getstringval ()
/*             , d_xmlresult.EXTRACT
                 ('//Messaggio/text()'
                 , 'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"'
                 ).getstringval ()     */
         INTO d_esito
             ,p_idDocument
/*             ,d_messaggio_errore */
         FROM DUAL
         ;
--dbms_output.put_line('Esito: '||d_esito);
--dbms_output.put_line('Id.Documento: '||p_idDocument);
    ELSE
       SELECT d_xmlresult.EXTRACT
                 ('//result/text()'
                 , 'xmlns:soap="http://www.w3.org/2003/05/soap-envelope"'
                 ).getstringval ()
             , d_xmlresult.EXTRACT
                 ('//errStr/text()'
                 , 'xmlns:soap="http://www.w3.org/2003/05/soap-envelope"'
                 ).getstringval ()
         INTO d_esito
             ,d_messaggio_errore
         FROM DUAL
         ;
/*         IF d_messaggio_errore is not null then
           d_esito := 'NEGATIVO';
         END IF;  */
    END IF;
     if d_esito = '0' then
       if p_idDocument is not null then
          update documenti_contribuente
             set id_documento_gdm = p_idDocument
           where cod_fiscale = p_cod_fiscale
             and sequenza = d_progr
             and nome_file = d_nome_file
             ;
       end if;
     else
        p_code_errore := -100;
        p_descr_errore := d_messaggio_errore;
     end if;
     commit;
  EXCEPTION
     WHEN ERRORE THEN
         rollback;
     WHEN OTHERS THEN
         p_descr_errore := sqlerrm;
         p_code_errore := sqlcode;
         rollback;
  END;
END invio_documento_old;
END;
/
