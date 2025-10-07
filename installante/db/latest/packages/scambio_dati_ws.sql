--liquibase formatted sql 
--changeset abrandolini:20250326_152429_scambio_dati_ws stripComments:false runOnChange:true 
 
create or replace package scambio_dati_ws is
wpkg_ws_servizio   number(2) := 1; -- identificativo servizio
wpkg_ws_servizio2  number(2); -- progressivo interno a identificativo servizio (facoltativo)
/*ATTENZIONE! Il codice azienda viene controllato in GET_SERVICE e GET_SOAP_REQUEST: in caso di inserimento
di un nuovo cliente occorre gestire entrambe le funzioni */
function           decode_utf8_clob           (in_text in clob) return clob;
function           decode_utf8                (in_text in varchar2) return varchar2;
function           proteggi                   (in_text in varchar2) return varchar2;
function           elimina_tag_versione       (in_clob in clob)   return clob;
function           get_service                (p_cod_integrazione in number
                                              ,p_cod_ente         in varchar2)   return varchar2;
function           get_soap_request           (p_xml in clob
                                              ,p_cod_integrazione  in number
                                              ,p_cod_ente in varchar2) return clob;
--function           F_SCAMBIO_WS               (file_in IN CLOB) RETURN CLOB;
function           get_codice_integrazione    (p_valore in varchar2) return number;
function           get_descr_integrazione     (p_cod_integrazione in number) return varchar2;
end;
/

CREATE OR REPLACE PACKAGE BODY scambio_dati_ws IS
   TYPE R_richiesta IS RECORD   -- Record come vuoi usarlo
      (tipo varchar2(1)
      ,anno_richiesta number
      ,numero_richiesta number
      ,progr_label number
      );
   TYPE T_Richieste IS TABLE OF R_richiesta INDEX BY BINARY_INTEGER;
   FUNCTION decode_utf8_clob (in_text IN CLOB)
      RETURN CLOB IS
      out_text                                           CLOB := in_text;
   BEGIN
      -- caratteri speciali
      out_text := REPLACE (out_text, CHR (38) || 'gt;', '>');
      out_text := REPLACE (out_text, CHR (38) || 'lt;', '<');
      out_text := REPLACE (out_text, CHR (38) || 'amp;', CHR (38));
      out_text := REPLACE (out_text, CHR (38) || 'quot;', '"');
      out_text := REPLACE (out_text, CHR (38) || 'apos;', '^');
      out_text := REPLACE (out_text, CHR (38) || '#167;', '°');
      -- eliminati perche' sconosciuti
      out_text := REPLACE (out_text, ']]>', NULL);
      -- circoletto non supportato
      out_text := REPLACE (out_text, '<![CDATA[', NULL);
      -- punto interrogativo rovesciato
      out_text := REPLACE (out_text, CHR (191), '');
      out_text := REPLACE (out_text, CHR (150), '');
      out_text := REPLACE (out_text, CHR (146), '''');
      out_text := REPLACE (out_text, CHR (147), '''');
      out_text := REPLACE (out_text, CHR (148), '''');
      out_text := REPLACE (out_text, CHR (153), '''');
      out_text := REPLACE (out_text, CHR (156), '''');
      -- 3 puntini attaccati
      out_text := REPLACE (out_text, CHR (133), '');
      RETURN out_text;
   END decode_utf8_clob;
   FUNCTION decode_utf8 (in_text IN VARCHAR2)
      RETURN VARCHAR2 IS
      out_text                                          VARCHAR2 (32000)
                                                                   := in_text;
   BEGIN
      -- lettere accentate
      out_text := REPLACE (out_text, CHR (224), 'A''');
      out_text := REPLACE (out_text, CHR (232), 'E''');
      out_text := REPLACE (out_text, CHR (233), 'E''');
      out_text := REPLACE (out_text, CHR (236), 'I''');
      out_text := REPLACE (out_text, CHR (242), 'O''');
      out_text := REPLACE (out_text, CHR (249), 'U''');
      out_text := REPLACE (out_text, CHR (192), 'A''');
      out_text := REPLACE (out_text, CHR (200), 'E''');
      -- caratteri speciali
      out_text := REPLACE (out_text, CHR (38) || 'apos;', '''');
      out_text := REPLACE (out_text, CHR (38) || 'quot;', '"');
      out_text := REPLACE (out_text, CHR (38) || 'gt;', '>');
      out_text := REPLACE (out_text, CHR (38) || 'lt;', '<');
      out_text := REPLACE (out_text, CHR (38) || 'amp;', CHR (38));
      -- eliminati perche' sconosciuti
      out_text := REPLACE (out_text, CHR (176), '');
      out_text := REPLACE (out_text, CHR (226), '');
      -- circoletto non supportato
      out_text := REPLACE (out_text, CHR (128), '');
      -- punto interrogativo rovesciato
      out_text := REPLACE (out_text, CHR (191), '');
      out_text := REPLACE (out_text, CHR (150), '');
      out_text := REPLACE (out_text, CHR (146), '''');
      out_text := REPLACE (out_text, CHR (147), '''');
      out_text := REPLACE (out_text, CHR (148), '''');
      out_text := REPLACE (out_text, CHR (153), '''');
      out_text := REPLACE (out_text, CHR (156), '''');
      -- 3 puntini attaccati
      out_text := REPLACE (out_text, CHR (133), '');
      out_text := REPLACE (out_text, CHR (9)||CHR(9), '  ');
      RETURN out_text;
   END decode_utf8;
   FUNCTION proteggi (in_text IN VARCHAR2)
      RETURN VARCHAR2 IS
      out_text VARCHAR2 (32000):= in_text;
   BEGIN
      -- lettere accentate
      out_text := REPLACE (out_text, CHR (224), 'a''');
      out_text := REPLACE (out_text, CHR (232), 'e''');
      out_text := REPLACE (out_text, CHR (233), 'e''');
      out_text := REPLACE (out_text, CHR (236), 'i''');
      out_text := REPLACE (out_text, CHR (242), 'o''');
      out_text := REPLACE (out_text, CHR (249), 'u''');
      out_text := REPLACE (out_text, CHR (192), 'a''');
      out_text := REPLACE (out_text, CHR (200), 'E''');
      out_text := REPLACE (out_text, CHR (201), 'E''');
      -- lettere accentate Pisana
      out_text := REPLACE (out_text, CHR (50080), 'a''');
      out_text := REPLACE (out_text, CHR (50088), 'e''');
      out_text := REPLACE (out_text, CHR (50089), 'e''');
      out_text := REPLACE (out_text, CHR (50092), 'i''');
      out_text := REPLACE (out_text, CHR (50098), 'o''');
      out_text := REPLACE (out_text, CHR (50105), 'u''');
      out_text := REPLACE (out_text, CHR (50056), 'E''');
      out_text := REPLACE (out_text, CHR (50057), 'E''');
--      -- eliminati perche' sconosciuti
      out_text := REPLACE (out_text, CHR (176), '');
      out_text := REPLACE (out_text, CHR (226), '');
--      -- circoletto non supportato
      out_text := REPLACE (out_text, CHR (128), 'E');
--      -- punto interrogativo rovesciato
      out_text := REPLACE (out_text, CHR (191), 'E');
      out_text := REPLACE (out_text, CHR (150), '');
      out_text := REPLACE (out_text, CHR (146), '''');
      out_text := REPLACE (out_text, CHR (147), '''');
      out_text := REPLACE (out_text, CHR (148), '''');
      out_text := REPLACE (out_text, CHR (153), '''');
      out_text := REPLACE (out_text, CHR (156), '''');
      out_text := REPLACE (out_text, CHR (216), 'O'); -- simbolo diametro
      out_text := REPLACE (out_text, CHR (31), ' '); -- simbolo tab
      out_text := REPLACE (out_text, CHR (2), ''); -- simbolo angolo alto a destra
--      -- 3 puntini attaccati
      out_text := REPLACE (out_text, CHR (133), '');
      out_text := REPLACE (out_text, CHR (9)||CHR(9), '  ');
      RETURN out_text;
   END proteggi;
   FUNCTION elimina_tag_versione(in_clob in clob)
   RETURN CLOB
   IS
     out_clob                                          CLOB := in_clob;
     tmp_pos_iniziale                                  number;
     tmp_pos_finale                                    number;
     tmp_da_eliminare                                  varchar2(1000);
   BEGIN
     while instr(out_clob,'<?') > 0 loop
       begin
         tmp_pos_iniziale := instr(out_clob,'<?');
         tmp_pos_finale := instr(out_clob,'?>');
         tmp_da_eliminare := substr(out_clob,tmp_pos_iniziale,tmp_pos_finale - tmp_pos_iniziale + 2);
         out_clob := replace(out_clob,tmp_da_eliminare,'');
       end;
     end loop;
     return out_clob;
   END;
   FUNCTION get_header (p_tipo             in varchar2
                       ,p_cod_integrazione in number
                       ,p_cod_ente         in varchar2)
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
             where codice_istat              = p_cod_ente
               and codice_integrazione       = p_cod_integrazione
               and w.identificativo_servizio = wpkg_ws_servizio
                    ;
         ELSE
             select nvl(w.header_action,'')
              into d_ritorno
              from ws_indirizzi_integrazione w
             where codice_istat              = p_cod_ente
               and codice_integrazione       = p_cod_integrazione
               and w.identificativo_servizio = wpkg_ws_servizio
                    ;
         END IF;
      EXCEPTION
          when no_data_found then
            raise_application_error(-20999,'Occorre gestire la tabella WS_INDIRIZZI_INTEGRAZIONE ('
                                    ||get_descr_integrazione(p_cod_integrazione)||')');
      END;
      return d_ritorno;
   END get_header;
   FUNCTION get_service (p_cod_integrazione in number
                        ,p_cod_ente         in varchar2)
   RETURN VARCHAR2 IS
   /******************************************************************************
   NOME:        GET_SERVICE
   DESCRIZIONE: Restituisce l'url completo per l'invio dei carichi o della richiesta
                giacenze per ogni cliente.
   PARAMETRI:   p_cod_integrazione  identificativo del cliente e servizio
   RITORNA:     stringa varchar2 contenente url
   ******************************************************************************/
      d_ritorno            VARCHAR(32000);
   BEGIN
      BEGIN
          select w.indirizzo_url||'/'||w.web_service
            into d_ritorno
            from ws_indirizzi_integrazione w
           where codice_istat              = p_cod_ente
             and codice_integrazione       = p_cod_integrazione
             and w.identificativo_servizio = wpkg_ws_servizio
                  ;
      EXCEPTION
          when no_data_found then
            raise_application_error(-20999,'Occorre gestire la tabella WS_INDIRIZZI_INTEGRAZIONE ('
                                    ||get_descr_integrazione(p_cod_integrazione)||')');
      END;
      return d_ritorno;
   END get_service;
   FUNCTION get_soap_request(
   p_xml               in   clob
 , p_cod_integrazione  in   number
 , p_cod_ente          in   varchar2)
   RETURN CLOB IS
   d_soap_request CLOB;
   BEGIN
      BEGIN
        select decode(wini.testo_iniziale_envelope,'#','',wini.testo_iniziale_envelope)
               || p_xml
               || decode(wini.testo_finale_envelope,'#','',wini.testo_finale_envelope)
          into d_soap_request
          from WS_INDIRIZZI_INTEGRAZIONE wini
         where wini.codice_istat            = p_cod_ente
           and wini.identificativo_servizio = wpkg_ws_servizio
           and wini.codice_integrazione     = p_cod_integrazione
           ;
      EXCEPTION
          when no_data_found then
            raise_application_error(-20999,'Occorre gestire la tabella WS_INDIRIZZI_INTEGRAZIONE '
                                   ||get_descr_integrazione(p_cod_integrazione));
      END;
      return d_soap_request;
   END;
function TO_NUMERO
(in_numero           in varchar2
,in_error            in number default 1
) return number
is
  out_numero         varchar2(100) := in_numero;
begin
  begin
    out_numero := to_number(out_numero, '999G999G999G999G999G999G999G999G999G990D00', 'NLS_NUMERIC_CHARACTERS=''. ''');
    return to_number(out_numero);
  exception when value_error then
      out_numero := replace(out_numero,'.',',');
      out_numero := replace(out_numero,' ','');
      return to_number(out_numero);
  end;
exception when value_error then
  if in_error = 1 then
    raise_application_error(-20903,'Numero non valido ('||out_numero||')');
  else
    return null;
  end if;
end;
--   FUNCTION f_scambio_ws (file_in IN CLOB)
--      RETURN CLOB IS
--      xml_request                                       xmltype;
--      xml_response                                      xmltype;
--      xml_out                                           clob;
--      tmp_clob                                          clob := file_in;
--      pos                                               number;
--      pos2                                              number;
--      repl                                              varchar2 (2000);
--      err                                               varchar2(32000);
--      errore                                            exception;
--   BEGIN
--      dbms_session.modify_package_state(dbms_session.reinitialize);
--      if tmp_clob like '%listaRichiesteProdotti%' then
--         if tmp_clob like '%&lt;tipoOperazione&gt;AFR&lt;/tipoOperazione&gt;%' then
--            tmp_clob := decode_utf8_clob (tmp_clob);
--         else
--         -- modifica del 10032014 per evitare errori quando il messaggio formattato correttamente
--         -- contiene caratteri speciali
--            null;
--         end if;
--      else
--         -- serve per trattare messaggi malformattati tipo quelli di erreffe
--         tmp_clob := decode_utf8_clob (tmp_clob);
--      end if;
--      pos := sa4_clob.INSTR (tmp_clob, 'xmlns', 1, 1);
--      WHILE pos <> 0 LOOP
--         pos2 := sa4_clob.INSTR (tmp_clob, '>', pos, 1);
--         repl := sa4_clob.SUBSTR (tmp_clob, pos, pos2 - pos);
--         tmp_clob := sa4_clob.REPLACE (tmp_clob, repl, '');
--         pos := sa4_clob.INSTR (tmp_clob, 'xmlns', pos2, 1);
--      END LOOP;
--      -- modifica del 220416 per evitare errore alla au_sudest
--      -- ORA-31011: Analisi XML non riuscita ORA-19202: Errore durante l'elaborazione XML LPX-00241: entity reference is not well formed
--      tmp_clob := replace(tmp_clob,chr (38), '_e_');
--      xml_request := XMLTYPE.createxml (tmp_clob);
--      begin
--        IF xml_request.EXISTSNODE ('//richiestaAnagrafiche') > 0 THEN
--           xml_response := richiesta_anagrafiche_resp (xml_request);
--        ELSIF xml_request.EXISTSNODE ('//listaScarichi') > 0 THEN
--           IF CodiceAzienda in ('090902','090203') THEN -- trattamento particolare per AO SCOTTE e ASL-SUDEST
--              xml_response := scarichi_resp_2 (xml_request);
--           ELSE
--              xml_response := scarichi_resp (xml_request);
--           END IF;
--        ELSIF xml_request.EXISTSNODE ('//listaRichiesteProdotti') > 0 THEN
--           xml_response := richieste_reparto_resp (xml_request);
--        ELSIF xml_request.EXISTSNODE ('//anagraficheSanitarie') > 0 THEN
--           xml_response := anagrafiche_sanitarie_resp (xml_request);
--        ELSIF xml_request.EXISTSNODE ('//listaConfermeCarichi') > 0 THEN
--           xml_response := conferme_carichi_resp (xml_request);
--        ELSIF xml_request.EXISTSNODE ('//richiestaStatoRichiesta') > 0 THEN
--           xml_response := stato_avanz_trans_resp (xml_request);
--        ELSIF xml_request.EXISTSNODE ('//listaBolle') > 0 THEN
--           xml_response := bolle_resi_resp (xml_request);
--        ELSIF xml_request.EXISTSNODE ('//listaConfermeCarichiMagazzino') > 0 THEN
--           xml_response := conferme_carichi_mag_resp (xml_request);
--        ELSIF xml_request.EXISTSNODE ('//listaConfermeScarichiMagazzino') > 0 THEN
--           xml_response := conferme_scarichi_mag_resp (xml_request);
--        ELSIF xml_request.EXISTSNODE ('//listaLettureOttiche') > 0 THEN
--           xml_response := letture_ottiche_resp (xml_request);
--        ELSIF xml_request.EXISTSNODE ('//listaContrattiEsterni') > 0 THEN
--           xml_response := scambio_dati_ws_ext1.contratti_esterni_resp (xml_request);
--        ELSIF xml_request.EXISTSNODE ('//ReportAllestimentoOrdine') > 0 THEN
--           xml_response := scambio_dati_ws_ext2.caric_evasioni_da_trascar_resp (xml_request);
--           COMMIT;
--        ELSIF xml_request.EXISTSNODE ('//ReportIngressoMerci') > 0 THEN
--           xml_response := scambio_dati_ws_ext2.caric_bolle_da_trascar_resp (xml_request);
--           COMMIT;
--        ELSIF xml_request.EXISTSNODE ('//listaProduzioneInterna') > 0 THEN
--           xml_response := scambio_dati_ws_ext5.produzione_interna_resp (xml_request);
--           COMMIT;
--        ELSE
--           err := 'Messaggio non riconosciuto';
--           raise errore;
--        END IF;
--      exception
--      when errore then raise;
--      end;
--      select xml_response.getclobval ()
--        into xml_out
--        from dual;
--      return xml_out;
--   EXCEPTION
--      when others then
--         if err is null then err := substr(sqlerrm,1,4000); end if;
--         scrivi_estav_wsxmldoc(file_in,err,'ERR',0,'');
--         return '<scambioDatiResponse>'||
--                         '<Result>ERROR '||err||'</Result>'||
--                         '</scambioDatiResponse>';
--   END f_scambio_ws;
   FUNCTION get_codice_integrazione( p_valore in varchar2)
   return number
   is
   d_codice                 number(3):=0;
   BEGIN
      if p_valore is not null then
          begin
            select codice_integrazione
              into d_codice
              from ws_integrazioni
             where upper(descrizione)||' ' like '% '||upper(p_valore)||' %';
           exception
              when no_data_found then
                   d_codice := 0;
           end;
       end if;
       return d_codice;
   END;
   FUNCTION get_descr_integrazione (p_cod_integrazione in number)
   return varchar2
   IS
   d_descrizione       WS_INTEGRAZIONI.DESCRIZIONE%TYPE;
   BEGIN
      begin
         select descrizione
           into d_descrizione
           from ws_integrazioni
          where codice_integrazione = p_cod_integrazione
          ;
      exception
        when no_data_found then
           d_descrizione := null;
      end;
      return d_descrizione;
   END;
END;
/

