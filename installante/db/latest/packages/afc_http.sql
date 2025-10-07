--liquibase formatted sql 
--changeset abrandolini:20250326_152429_afc_http stripComments:false runOnChange:true 
 
create or replace package AFC_HTTP is
/******************************************************************************
 Gestione chiamate classi Java esposte come istruzioni da una Servlet o da un web service di servizio al DataBase.
 REVISIONI.
 Rev.  Data        Autore  Descrizione.
 ----  ----------  ------  ----------------------------------------------------
 00    19/12/2007  VA      Prima emissione.
 01    19/06/2009  MM      Creazione sendwsrequest, set_service_timeout, get_service_timeout, set_content_type, get_content_type, set_soap_action, get_soap_action.
 02    29/08/2011  FT      Allineati i commenti col nuovo standard di plsqldoc.
******************************************************************************/
   -- Package revision value
   s_revisione constant VARCHAR2(30) := 'V1.02';
   procedure set_service_url
   ( p_url in varchar2
   );
   procedure set_method
   ( p_method in varchar2 default 'GET'
   );
   procedure set_session_wallet
   ( p_session_wallet in varchar2
   );
   procedure set_session_wallet_pwd
   ( p_session_wallet_pwd in varchar2
   );
   PROCEDURE set_service_timeout
   ( p_service_timeout in integer
   );
   PROCEDURE set_content_type
   ( p_content_type in varchar2
   );
   PROCEDURE set_soap_action
   ( p_soap_action in varchar2
   );
   /******************************************************************************
    Restituisce versione e revisione di distribuzione del package.
    %return varchar2: contiene versione e revisione.
    %note <UL>
          <LI> Primo numero: versione compatibilita del Package.</LI>
          <LI> Secondo numero: revisione del Package specification.</LI>
          <LI> Terzo numero: revisione del Package body.</LI>
          </UL>
   ******************************************************************************/
   function versione
   return varchar2;
   function get_service_url
   return varchar2;
   procedure set_servlet
   ( p_nome_servlet in varchar2
   );
   function get_servlet
   ( p_nome_servlet varchar2 default null
   ) return varchar2;
   function get_servlet_url
   ( p_nome_servlet varchar2 default null
   ) return varchar2;
   function get_service_timeout
   return integer;
   function get_content_type
   return varchar2;
   function get_soap_action
   return varchar2;
   function sendRequest
   ( p_request  in varchar2
   , p_user     in varchar2 default null
   , p_password in varchar2 default null
   ) return varchar2;
   function sendSoaRequest
   ( p_soaService in varchar2
   , p_soaAlias in varchar2
   , p_soaParameters in varchar2
   , p_user     in varchar2 default null
   , p_password in varchar2 default null
   ) return varchar2;
   function sendWSRequest
   ( p_soap_request in clob
   ) return clob;
end AFC_HTTP;

/
CREATE OR REPLACE PACKAGE BODY afc_http
AS
/******************************************************************************
 Gestione chiamate classi Java esposte come istruzioni da una Servlet o da un web service di servizio al DataBase.
 REVISIONS.
 Ver        Date        Author           Description
 ---------  ----------  ---------------  ------------------------------------
 001        15/01/2008   VA               Created this package body.
 002        19/06/2009   MM               Creazione sendwsrequest, set_service_timeout, get_service_timeout, set_content_type, get_content_type, set_soap_action, get_soap_action.
 003        23/10/2009   MM               Cambiata chiamata a afc_lob.add con afc_lob.c_add.
 004        29/08/2011   FT               Allineati i commenti col nuovo standard di plsqldoc.
******************************************************************************/
   s_revisione_body   CONSTANT afc.t_revision := '004';
   SUBTYPE t_service IS afc.t_message;
   s_service_url               t_service;
   SUBTYPE t_servlet IS afc.t_message;
   s_servlet                   t_servlet;
   s_method                    VARCHAR2 (10)  := 'GET';
   SUBTYPE t_path IS afc.t_message;
   s_session_wallet            t_path;
   d_password                  VARCHAR2 (100);
   SUBTYPE t_password IS d_password%TYPE;
   s_session_wallet_pwd        t_password;
   s_service_timeout           INTEGER        := 600;
   s_content_type              afc.t_message  := 'text/xml';
   s_soap_action               afc.t_message;
--------------------------------------------------------------------------------
   /******************************************************************************
    Restituisce versione e revisione di distribuzione del package.
   ******************************************************************************/
   FUNCTION versione
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN afc.VERSION (s_revisione, s_revisione_body);
   END;                                                  -- AFC_Error.versione
   PROCEDURE set_service_url (p_url IN VARCHAR2)
   IS
   BEGIN
      s_service_url := p_url;
   END;
   FUNCTION get_service_url
      RETURN VARCHAR2
   IS
      d_service_url   t_service;
      d_istanza       ad4_istanze.istanza%TYPE;
   BEGIN
      IF s_service_url IS NOT NULL
      THEN
         d_service_url := s_service_url;
      ELSE
         /* Se la variabile interna non è settata cerco di recuperare l'informazione da AD4*/
         d_istanza := si4.istanza;
         IF d_istanza IS NOT NULL
         THEN
            SELECT MAX (servizio)
              INTO d_service_url
              FROM ad4_istanze
             WHERE istanza = d_istanza AND servizio LIKE 'http%';
         ELSIF d_istanza IS NULL OR d_service_url IS NULL
         THEN
            SELECT MAX (servizio)
              INTO d_service_url
              FROM ad4_istanze
             WHERE user_oracle = USER AND servizio LIKE 'http%';
         END IF;
      END IF;
      d_service_url :=
            NVL (d_service_url, 'http://localhost:8080/' || LOWER (d_istanza));
      RETURN d_service_url;
   END;
   PROCEDURE set_servlet (p_nome_servlet IN VARCHAR2)
   IS
   BEGIN
      s_servlet := p_nome_servlet;
   END;
   PROCEDURE set_method (p_method IN VARCHAR2 DEFAULT 'GET')
   IS
   BEGIN
      IF UPPER (p_method) IN ('GET', 'POST')
      THEN
         s_method := UPPER (p_method);
      ELSE
         raise_application_error (-20999, 'Metodi previsti: GET - POST');
      END IF;
   END;
   PROCEDURE set_session_wallet (p_session_wallet IN VARCHAR2)
   IS
   BEGIN
      s_session_wallet := p_session_wallet;
   END;
   PROCEDURE set_service_timeout (p_service_timeout IN INTEGER)
   IS
   BEGIN
      s_service_timeout := p_service_timeout;
   END;
   PROCEDURE set_content_type (p_content_type IN VARCHAR2)
   IS
   BEGIN
      s_content_type := p_content_type;
   END;
   PROCEDURE set_soap_action (p_soap_action IN VARCHAR2)
   IS
   BEGIN
      s_soap_action := p_soap_action;
   END;
   FUNCTION get_wallet
      RETURN VARCHAR2
   IS
      d_wallet   t_path;
   BEGIN
      ad4_registro_utility.leggi_stringa ('PRODUCTS/AUTHENTICATION/HTTPS',
                                          'WALLET',
                                          d_wallet,
                                          FALSE
                                         );
      d_wallet := NVL (s_session_wallet, d_wallet);
      RETURN d_wallet;
   END;
   PROCEDURE set_session_wallet_pwd (p_session_wallet_pwd IN VARCHAR2)
   IS
   BEGIN
      s_session_wallet_pwd := p_session_wallet_pwd;
   END;
   FUNCTION get_wallet_pwd
      RETURN VARCHAR2
   IS
      d_wallet_pwd   t_password;
   BEGIN
      --registro_utility.leggi_stringa('PRODUCTS/AUTHENTICATION/HTTPS','PWDWALLET',d_wallet_pwd,false);
      BEGIN
         EXECUTE IMMEDIATE 'select registro_utility.leggi_stringa(''PRODUCTS/AUTHENTICATION/HTTPS'',''PWDWALLET'',false) from dual'
                      INTO d_wallet_pwd;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF SQLCODE = -904
            THEN
               d_wallet_pwd := '';
            ELSE
               RAISE;
            END IF;
      END;
      d_wallet_pwd := NVL (s_session_wallet_pwd, d_wallet_pwd);
      RETURN d_wallet_pwd;
   END;
   FUNCTION get_servlet (p_nome_servlet VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      d_servlet   t_servlet;
   BEGIN
      IF p_nome_servlet IS NULL
      THEN
         d_servlet := s_servlet;
      ELSE
         --registro_utility.leggi_stringa('PRODUCTS/SERVLET',p_nome_servlet,d_servlet,false);
         BEGIN
            EXECUTE IMMEDIATE 'select registro_utility.leggi_stringa(''PRODUCTS/SERVLET'',p_nome_servlet,false) from dual'
                         INTO d_servlet;
         EXCEPTION
            WHEN OTHERS
            THEN
               IF SQLCODE = -904
               THEN
                  d_servlet := '';
               ELSE
                  RAISE;
               END IF;
         END;
         d_servlet := NVL (d_servlet, p_nome_servlet);
      END IF;
      RETURN d_servlet;
   END;
   FUNCTION get_servlet_url (p_nome_servlet VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      d_servlet_url   t_servlet;
   BEGIN
      d_servlet_url := get_service_url || '/' || get_servlet (p_nome_servlet);
      RETURN d_servlet_url;
   END;
   FUNCTION get_service_timeout
      RETURN INTEGER
   IS
   BEGIN
      RETURN s_service_timeout;
   END;
   FUNCTION get_content_type
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN s_content_type;
   END;
   FUNCTION get_soap_action
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN s_soap_action;
   END;
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
      r             UTL_HTTP.req;
   BEGIN
      d_request := replace(utl_url.ESCAPE (url => p_request), '#', '%23');                   --, true);
      --dbms_output.put_line(substr(d_request,1,250));
      IF INSTR (LOWER (d_request), 'https') > 0
      THEN
         --utl_http.set_wallet('file:/oracle/app/oracle/admin/PAL','lavoro17');
         UTL_HTTP.set_wallet (get_wallet, get_wallet_pwd);
      END IF;
      d_http_req :=
              UTL_HTTP.begin_request (d_request, s_method             --'POST'
                                                         ,
                                      'HTTP/1.1');
      IF p_user IS NOT NULL
      THEN
         UTL_HTTP.set_authentication (d_http_req, p_user, p_password);
      END IF;
      d_http_resp := UTL_HTTP.get_response (d_http_req);
      UTL_HTTP.read_text (d_http_resp, d_response);
      -- dbms_output.put_line(d_http_resp.status_code||' - '||d_http_resp.reason_phrase);
      UTL_HTTP.end_response (d_http_resp);
      -- utl_http.end_request(d_http_req);
      RETURN d_response;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error (-20999,
                                     d_http_resp.status_code
                                  || ' - '
                                  || d_http_resp.reason_phrase,
                                  TRUE
                                 );
   --raise;
   END;
   FUNCTION sendsoarequest (
      p_soaservice      IN   VARCHAR2,
      p_soaalias        IN   VARCHAR2,
      p_soaparameters   IN   VARCHAR2,
      p_user            IN   VARCHAR2 DEFAULT NULL,
      p_password        IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2
   IS
      d_request    afc.t_statement;
      d_response   afc.t_statement;
   BEGIN
      d_request :=
            get_servlet_url (p_soaservice)
         || '?'
         || p_soaalias
         || '&'
         || p_soaparameters;

      d_response := sendrequest (d_request, p_user, p_password);
      RETURN d_response;
   END;
   FUNCTION sendwsrequest (p_soap_request IN CLOB)
      RETURN CLOB
   IS
      d_soap_response        CLOB;
      d_clob_dep             CLOB;
      d_soap_response_5000   CLOB;
      d_soap_response_line   VARCHAR2 (32767);
      http_request           UTL_HTTP.req;
      http_response          UTL_HTTP.resp;
      d_amount               BINARY_INTEGER;
      d_table_request        DBMS_SQL.varchar2s;
      d_length               NUMBER             := 0;
      i                      NUMBER             := 0;
   BEGIN
      afc_lob.set_row_len(252);
      afc_lob.riempi_text_table (d_table_request, p_soap_request);
      UTL_HTTP.set_transfer_timeout (get_service_timeout ());
      set_method ('POST');
      http_request :=
                 UTL_HTTP.begin_request (s_service_url, s_method, 'HTTP/1.1');
      UTL_HTTP.set_header (http_request, 'Content-Type', get_content_type ());
      UTL_HTTP.set_header (http_request, 'SOAPAction', get_soap_action ());
      FOR i IN NVL (d_table_request.FIRST, 0) .. NVL (d_table_request.LAST,
                                                      0)
      LOOP
         d_length := d_length + LENGTH (d_table_request (i)) + 2;
      END LOOP;
      UTL_HTTP.set_header (http_request, 'Content-Length', d_length);
      FOR i IN NVL (d_table_request.FIRST, 0) .. NVL (d_table_request.LAST, 0)
      LOOP
         --DBMS_OUTPUT.put_line (d_table_request (i));
         UTL_HTTP.write_line (http_request, d_table_request (i));
      END LOOP;
      http_response := UTL_HTTP.get_response (http_request);
      --UTL_HTTP.Set_Body_Charset(http_response, 'UTF-8');
      DBMS_LOB.createtemporary (d_soap_response, FALSE, DBMS_LOB.CALL);
      BEGIN
         LOOP
            i := i + 1;
            UTL_HTTP.read_line (http_response, d_soap_response_line, FALSE);
            d_soap_response_line := afc_lob.encode_utf8 (d_soap_response_line);
            d_soap_response_5000 :=
                   afc_lob.c_ADD (d_soap_response_5000,
                                (d_soap_response_line));
            IF MOD (i, 5000) = 0
            THEN
               d_soap_response := d_soap_response || d_soap_response_5000;
               d_soap_response_5000 := NULL;
            END IF;
         END LOOP;
         UTL_HTTP.end_response (http_response);
      EXCEPTION
         WHEN UTL_HTTP.end_of_body
         THEN
            UTL_HTTP.end_response (http_response);
      END;
      d_soap_response := d_soap_response || d_soap_response_5000;
      RETURN d_soap_response;
   EXCEPTION
      WHEN OTHERS
      THEN
         UTL_HTTP.end_response (http_response);
         RAISE;
   END;
END afc_http;
/
