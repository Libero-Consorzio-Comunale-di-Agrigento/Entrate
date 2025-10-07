--liquibase formatted sql 
--changeset abrandolini:20250326_152429_web_importa_dati stripComments:false runOnChange:true 
 
create or replace package WEB_IMPORTA_DATI is
  function web_carica_dic_notai(
    a_documento_id    IN       NUMBER,
    a_utente          IN       VARCHAR2,
    a_ctr_denuncia    IN       VARCHAR2,
    a_sezione_unica   IN       VARCHAR2,
    a_fonte           IN       NUMBER) return VARCHAR2;
  function web_alde_risposta(
       a_documento_id     in      number
     , a_nome_supporto    in      varchar2
     , a_utente           in      varchar2
     ) return VARCHAR2;
  function web_flusso_ritorno_mav(
    a_documento_id     in      number
  , a_utente           in      varchar2
  ) return VARCHAR2;
  function web_flusso_ritorno_mav_tarsu(
       a_documento_id     in      number
     , a_utente           in      varchar2
     , a_spese            in      number
     ) return VARCHAR2;
  function web_flusso_ritorno_m_t_rm(
       a_documento_id     in      number
     , a_utente           in      varchar2
     , a_spese            in      number
     ) return VARCHAR2;
  function  web_flusso_rit_mav_ici_viol(
       a_documento_id     in      number
     , a_utente           in      varchar2
     , a_spese            in      number
     ) return VARCHAR2;
--  function  web_importa_vers_cosap_poste(
--       a_documento_id     in      number
--     , a_utente           in      varchar2
--     ) return VARCHAR2;
--
  function  web_flusso_ritorno_rid(
       a_documento_id     in      number
     , a_utente           in      varchar2
     ) return VARCHAR2;
  function  web_carica_dic_successioni(
       a_documento_id     in      number
     , a_utente           in      varchar2
     , a_ctr_denuncia     in      varchar2
     , a_sezione_unica    in      varchar2
     , a_fonte            in      number
     ) return VARCHAR2;
   function web_carica_versamenti_titr_F24(
        a_documento_id     in      number
      , a_utente           in      varchar2
      ) return VARCHAR2;
   function web_carica_docfa(
        a_documento_id    in      number,
        a_utente          in      varchar2,
        a_sezione_unica   in      varchar2,
        a_fonte           in      NUMBER) return VARCHAR2;
--   function WEB_IMPORTA_VERS_COSAP_POSTE(
--        a_documento_id     in      number
--      , a_utente           in      varchar2
--      ) return VARCHAR2;
--
     end WEB_IMPORTA_DATI;
/

CREATE OR REPLACE PACKAGE body WEB_IMPORTA_DATI
IS
FUNCTION web_carica_dic_notai(
    a_documento_id  IN NUMBER,
    a_utente        IN VARCHAR2,
    a_ctr_denuncia  IN VARCHAR2,
    a_sezione_unica IN VARCHAR2,
    a_fonte         IN NUMBER)
  RETURN VARCHAR2
IS
  w_messaggio VARCHAR2 (4000);
BEGIN
  carica_dic_notai ( a_documento_id, a_utente, a_ctr_denuncia, a_sezione_unica, a_fonte, w_messaggio);
  RETURN w_messaggio;
END;
FUNCTION web_alde_risposta(
       a_documento_id     in      number
     , a_nome_supporto    in      varchar2
     , a_utente           in      varchar2
     )
  RETURN VARCHAR2
IS
  w_messaggio VARCHAR2 (4000);
BEGIN
  alde_risposta(a_documento_id, a_nome_supporto, a_utente,  w_messaggio);
  RETURN w_messaggio;
END;
FUNCTION web_flusso_ritorno_mav(
       a_documento_id     in      number
     , a_utente           in      varchar2
     )
  RETURN VARCHAR2
IS
  w_messaggio VARCHAR2 (4000);
BEGIN
  flusso_ritorno_mav(a_documento_id, a_utente,  w_messaggio);
  RETURN w_messaggio;
END;
FUNCTION web_flusso_ritorno_mav_tarsu(
       a_documento_id     in      number
     , a_utente           in      varchar2
     , a_spese            in      number
     )
      RETURN VARCHAR2
IS
  w_messaggio VARCHAR2 (4000);
BEGIN
  flusso_ritorno_mav_tarsu(a_documento_id, a_utente, a_spese,  w_messaggio);
  RETURN w_messaggio;
END;
FUNCTION web_flusso_ritorno_m_t_rm(
       a_documento_id     in      number
     , a_utente           in      varchar2
     , a_spese            in      number
     )
      RETURN VARCHAR2
IS
  w_messaggio VARCHAR2 (4000);
BEGIN
  flusso_ritorno_mav_tarsu_rm(a_documento_id, a_utente, a_spese,  w_messaggio);
  RETURN w_messaggio;
END;
FUNCTION web_flusso_rit_mav_ici_viol(
       a_documento_id     in      number
     , a_utente           in      varchar2
     , a_spese            in      number
     )
      RETURN VARCHAR2
IS
  w_messaggio VARCHAR2 (4000);
BEGIN
  flusso_ritorno_mav_ici_viol(a_documento_id, a_utente, a_spese,  w_messaggio);
  RETURN w_messaggio;
END;
--FUNCTION web_importa_vers_cosap_poste(
--       a_documento_id     in      number
--     , a_utente           in      varchar2
--     )
--          RETURN VARCHAR2
--IS
--  w_messaggio VARCHAR2 (4000);
--BEGIN
--  importa_vers_cosap_poste(a_documento_id, a_utente,  w_messaggio);
--  RETURN w_messaggio;
-- END;
FUNCTION web_flusso_ritorno_rid(
       a_documento_id     in      number
     , a_utente           in      varchar2
     )
     RETURN VARCHAR2
IS
  w_messaggio VARCHAR2 (4000);
BEGIN
  flusso_ritorno_rid(a_documento_id, a_utente,  w_messaggio);
  RETURN w_messaggio;
END;
FUNCTION web_carica_dic_successioni(
       a_documento_id     in      number
     , a_utente           in      varchar2
     , a_ctr_denuncia     in      varchar2
     , a_sezione_unica    in      varchar2
     , a_fonte            in      number
     )
     RETURN VARCHAR2
IS
  w_messaggio VARCHAR2 (4000);
BEGIN
  carica_dic_successioni(a_documento_id, a_utente, a_ctr_denuncia, a_sezione_unica, a_fonte,  w_messaggio);
  RETURN w_messaggio;
END;
FUNCTION web_carica_versamenti_titr_F24(
        a_documento_id     in      number
      , a_utente           in      varchar2
      )
      RETURN VARCHAR2
IS
  w_messaggio VARCHAR2 (4000);
BEGIN
  carica_versamenti_titr_F24(a_documento_id, a_utente,  w_messaggio);
  RETURN w_messaggio;
END;
FUNCTION web_carica_docfa(
        a_documento_id    in      number,
        a_utente          in      varchar2,
        a_sezione_unica   in      varchar2,
        a_fonte           in      NUMBER)
     RETURN VARCHAR2
IS
  w_messaggio VARCHAR2 (4000);
BEGIN
  carica_docfa(a_documento_id, a_utente, a_sezione_unica, a_fonte,  w_messaggio);
  RETURN w_messaggio;
END;
END WEB_IMPORTA_DATI;
/

