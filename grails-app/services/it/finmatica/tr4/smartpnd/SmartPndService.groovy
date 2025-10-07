package it.finmatica.tr4.smartpnd

import com.google.gson.Gson
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.comunicazioni.Comunicazione
import it.finmatica.tr4.comunicazioni.Tassonomia
import it.finmatica.tr4.comunicazioni.TipoComunicazione
import it.finmatica.tr4.comunicazioni.payload.ComunicazionePayload
import it.finmatica.tr4.wslog.WsLogService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import wslite.http.HTTPRequest
import wslite.http.HTTPResponse
import wslite.http.auth.HTTPBasicAuthorization
import wslite.rest.ContentType
import wslite.rest.RESTClient
import wslite.rest.RESTClientException
import wslite.rest.Response

class SmartPndService {

    static String APPLICATIVO_TR4 = 'TRIBUTI'
    static String TITOLO_SMART_PND = 'SmartPND'
    public static final String TIPO_MOD_INVIO_APPIO = 'APPIO'
    public static final String TIPO_MOD_INVIO_EMAIL = 'MAIL'
    static final int OGGETTO_PND_MAX_LENGTH = 130
    static final int OGGETTO_APPIO_MIN_LENGTH = 10
    static final int OGGETTO_APPIO_MAX_LENGTH = 120
    static final int CONTENUTO_APPIO_MIN_LENGTH = 80
    static final int CONTENUTO_APPIO_MAX_LENGTH = 10000
    static final String INDIRIZZO_PND_NOT_ALLOWED_CHARS_MATCH_REGEX = /([^0-9A-z\.\/\s\'\-])/

    WsLogService wsLogService
    CommonService commonService

    private static Log log = LogFactory.getLog(SmartPndService)

    private final def SPND_URL = "SPND_URL"
    private final def SPND_USER = "SPND_USER"
    private final def SPND_PASS = "SPND_PASS"

    private fnWsURL = { ->
        def url = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == SPND_URL }?.valore ?: ""
        if (url?.endsWith('/')) {
            return url[1..url.size() - 1]
        }

        return url

    }
    private fnWsUser = { ->
        OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == SPND_USER }?.valore ?: ""
    }
    private fnWsPass = { ->
        OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == SPND_PASS }?.valore ?: ""
    }

    private RESTClient client

    enum TipoNotifica {
        PND,
        PEC,
        EMAIL,
        NONE
    }

    SmartPndService() {
        loadConfig()
    }

    def smartPNDAbilitato() {
        return !fnWsURL()?.trim()?.isEmpty()
    }

    def creaComunicazione(ComunicazionePayload comunicazione) {

        loadConfig()

        def path = "/creaComunicazione"

        log.info("Esecuzione [$path]")
        log.debug(comunicazione?.toJson()?.toString())

        def response = null
        try {
            response = client.post([
                    path          : path,
                    connectTimeout: 5000,
                    readTimeout   : 10000,
                    accept        : ContentType.JSON
            ], {
                type ContentType.JSON
                text comunicazione.toJson()
            })

            responseValidation(response)

            if (!response.json.idComunicazione) {
                throw new InvalidResponseException('idComunicazione non valido')
            }

            logSuccess(response)

            return response.json.idComunicazione
        } catch (InvalidResponseException e) {
            logError(response.request, response.response, e)
            throw e
        } catch (RESTClientException e) {
            logError(e.request, e.response, e)
            throw e
        } catch (Exception e) {
            logError(response?.request, response?.response, e)
            throw e
        }
    }

    def uploadFileComunicazione(def idComunicazione, def filename, byte[] file) {

        loadConfig()

        def path = "/uploadFileComunicazione"

        log.info("Esecuzione [$path]")

        def mimeType = commonService.detectMimeType(file)

        def response = null
        try {
            response = client.post([
                    path          : path,
                    connectTimeout: 5000,
                    readTimeout   : 10000,
                    accept        : ContentType.JSON
            ], {
                multipart 'idComunicazione', (idComunicazione as String).bytes
                multipart 'filename', (filename as String).bytes
                multipart 'file', file, mimeType.toString(), (filename as String)
            })

            responseValidation(response)

            if (!response.json.idComunicazione) {
                throw new InvalidResponseException('idComunicazione non valido')
            }

            logSuccess(response, idComunicazione)

            return response.json.idComunicazione
        } catch (InvalidResponseException e) {
            logError(response.request, response.response, e)
            throw e
        } catch (RESTClientException e) {
            logError(e.request, e.response, e)
            throw e
        } catch (Exception e) {
            logError(response?.request, response?.response, e)
            throw e
        }
    }

    def eliminaComunicazione(def idComunicazione) {

        loadConfig()

        def path = "/eliminaComunicazione"

        log.info("$path [$idComunicazione]")

        def response = null
        try {
            response = client.get(
                    path: path,
                    connectTimeout: 5000,
                    readTimeout: 10000,
                    accept: ContentType.JSON,
                    query: [idComunicazione: idComunicazione]
            )

            responseValidation(response)

            if (!response.json.idComunicazione) {
                throw new InvalidResponseException('idComunicazione non valido')
            }

            logSuccess(response, idComunicazione)

            return true
        } catch (InvalidResponseException e) {
            logError(response.request, response.response, e)
            throw e
        } catch (RESTClientException e) {
            logError(e.request, e.response, e)
            throw e
        } catch (Exception e) {
            logError(response?.request, response?.response, e)
            throw e
        }
    }

    def abilitaComunicazione(def idComunicazione) {

        loadConfig()

        def path = "/abilitaComunicazione"

        log.info("$path [$idComunicazione]")

        def response = null
        try {
            response = client.get(path: path,
                    connectTimeout: 5000,
                    readTimeout: 10000,
                    accept: ContentType.JSON,
                    query: [idComunicazione: idComunicazione])

            responseValidation(response)

            if (!response.json.idComunicazione) {
                throw new InvalidResponseException('idComunicazione non valido')
            }

            logSuccess(response, idComunicazione)

            return true
        } catch (InvalidResponseException e) {
            logError(response.request, response.response, e)
            throw e
        } catch (RESTClientException e) {
            logError(e.request, e.response, e)
            throw e
        } catch (Exception e) {
            logError(response?.request, response?.response, e)
            throw e
        }
    }

    def disabilitaComunicazione(def idComunicazione) {

        loadConfig()

        def path = "/disabilitaComunicazione"

        log.info("$path [$idComunicazione]")

        def response = null
        try {
            response = client.get(
                    path: path,
                    connectTimeout: 5000,
                    readTimeout: 10000,
                    accept: ContentType.JSON,
                    query: [idComunicazione: idComunicazione]
            )

            responseValidation(response)

            if (!response.json.idComunicazione) {
                throw new InvalidResponseException('idComunicazione non valido')
            }

            logSuccess(response, idComunicazione)

            return true
        } catch (InvalidResponseException e) {
            logError(response.request, response.response, e)
            throw e
        } catch (RESTClientException e) {
            logError(e.request, e.response, e)
            throw e
        } catch (Exception e) {
            logError(response?.request, response?.response, e)
            throw e
        }
    }

    def getComunicazione(def idComunicazione) {

        loadConfig()

        def path = "/getComunicazione"

        log.info("$path [$idComunicazione]")

        def response = null
        try {
            response = client.get(
                    path: path,
                    connectTimeout: 5000,
                    readTimeout: 10000,
                    accept: ContentType.JSON,
                    query: [idComunicazione: idComunicazione]
            )

            responseValidation(response)

            def result = (new Comunicazione(idComunicazione)).fromJson(response.text)

            logSuccess(response, idComunicazione)

            return result
        } catch (InvalidResponseException e) {
            logError(response.request, response.response, e)
            throw e
        } catch (RESTClientException e) {
            logError(e.request, e.response, e)
            throw e
        } catch (Exception e) {
            logError(response?.request, response?.response, e)
            throw e
        }
    }

    def getComunicazioneFromApplicativo(def applicativo, def idRifApplicativo, def codEnte) {
        def path = "/getComunicazioneFromApplicativo"

        log.info("$path [$applicativo, $idRifApplicativo, $codEnte]")

        def response = null
        try {
            response = client.get(
                    path: path,
                    connectTimeout: 5000,
                    readTimeout: 10000,
                    accept: ContentType.JSON,
                    query: [applicativo: applicativo, idRifApplicativo: idRifApplicativo, codEnte: codEnte]
            )

            responseValidation(response)

            def result = (new Comunicazione()).fromJson(response.text)

            logSuccess(response)

            return result
        } catch (InvalidResponseException e) {
            logError(response.request, response.response, e)
            throw e
        } catch (RESTClientException e) {
            logError(e.request, e.response, e)
            throw e
        } catch (Exception e) {
            logError(response?.request, response?.response, e)
            throw e
        }
    }

    def getComunicazioneAllegato(def idComunicazione, def filename) {
        loadConfig()

        def path = "/getComunicazioneAllegato"

        log.info("$path [$idComunicazione, $filename]")

        def response = null
        try {
            response = client.get(
                    path: path,
                    connectTimeout: 5000,
                    readTimeout: 10000,
                    accept: ContentType.BINARY,
                    query: [idComunicazione: idComunicazione, filename: filename]
            )

            if (response.statusCode != 200) {
                throw new InvalidResponseException("Ritornato status ${response.statusCode}")
            }

            if (!response.data || response.data.size() == 0) {
                throw new InvalidResponseException("Ritornato file vuoto")
            }

            logSuccess(response, idComunicazione)

            return response.data
        } catch (InvalidResponseException e) {
            logError(response.request, response.response, e)
            throw e
        } catch (RESTClientException e) {
            logError(e.request, e.response, e)
            throw e
        } catch (Exception e) {
            logError(response?.request, response?.response, e)
            throw e
        }
    }

    def listaTipologieComunicazione() {

        loadConfig()

        def path = "/listaTipologieComunicazione"

        log.info(path)

        def response = null
        try {
            response = client.get(
                    path: path,
                    connectTimeout: 5000,
                    readTimeout: 10000,
                    accept: ContentType.JSON,
                    query: [applicativo: APPLICATIVO_TR4]
            )

            responseValidation(response)

            if (!response.text.trim()) {
                throw new IllegalArgumentException("Il json non può essere vuoto o nullo")
            }

            def result = (new Gson()).fromJson(response.text, TipoComunicazione[].class)

            logSuccess(response)

            return result
        } catch (InvalidResponseException e) {
            logError(response.request, response.response, e)
            throw e
        } catch (RESTClientException e) {
            logError(e.request, e.response, e)
            throw e
        } catch (Exception e) {
            logError(response?.request, response?.response, e)
            throw e
        }

    }

    def getTassomonima(def codice) {
        return listaTassonomie()?.tassonomiaPND?.find { it.codice == codice }
    }

    def tassonomiaConPagamento(def codice) {
        return getTassomonima(codice)?.pagamento == 'si'
    }

    private def listaTassonomie() {

        loadConfig()

        def path = "/getTassonomiePND"

        log.info(path)

        def response = null
        try {
            response = client.get(
                    path: path,
                    connectTimeout: 5000,
                    readTimeout: 10000,
                    accept: ContentType.JSON,
            )

            responseValidation(response)

            if (!response.text.trim()) {
                throw new IllegalArgumentException("Codici tassonomici non definiti")
            }

            def result = (new Gson()).fromJson(response.text, Tassonomia.class)

            logSuccess(response)

            return result
        } catch (InvalidResponseException e) {
            logError(response.request, response.response, e)
            throw e
        } catch (RESTClientException e) {
            logError(e.request, e.response, e)
            throw e
        } catch (Exception e) {
            logError(response?.request, response?.response, e)
            throw e
        }
    }

    def getListaModInvio(Comunicazione comunicazione) {
        def modInvioList = comunicazione.invioAppIO.collect {
            [tipo              : TIPO_MOD_INVIO_APPIO,
             nominativoMittente: it.codiceFiscaleMittente,
             oggetto           : it.oggetto ?: comunicazione.oggetto,
             destinatari       : '',
             testo             : it.testo]
        }

        modInvioList += comunicazione.invioMail.collect {
            [tipo              : 'MAIL',
             nominativoMittente: it.nominativoMittente,
             oggetto           : it.oggetto ?: comunicazione.oggetto,
             destinatari       : it.destinatari.mail.join(', '),
             testo             : it.testo]
        }

        modInvioList += comunicazione.invioPND.collect {
            [tipo              : 'PND',
             nominativoMittente: it.nominativoMittente,
             oggetto           : it.oggetto ?: comunicazione.oggetto,
             destinatari       : '']
        }

        return modInvioList
    }

    private responseValidation(def response) {

        if (response.statusCode != 200) {
            throw new InvalidResponseException("Ritornato status ${response.statusCode}")
        }

        if (response.json?.status == 'KO' && response?.json.message) {
            throw new InvalidResponseException(response.json.message)
        }
    }

    private loadConfig() {
        if (!(fnWsURL()?.trim())) {
            log.info("$TITOLO_SMART_PND non configurato.")
        } else {
            log.info("Lettura URL $TITOLO_SMART_PND [${fnWsURL()}]")
        }

        if (client) {
            client.url = fnWsURL()
        } else {
            client = new RESTClient(fnWsURL())
        }

        client.authorization = new HTTPBasicAuthorization(fnWsUser(), fnWsPass())
    }

    private logSuccess(Response response, def idComunicazione = null) {
        wsLogService.saveSmartPndLog([
                requestMethod  : response.request.method,
                requestUrl     : response.request.url,
                requestContent : response.request.contentAsString,
                responseContent: response.json ? response.json.toString(3) : response.text,
                idComunicazione: idComunicazione])
    }

    private logError(HTTPRequest request, HTTPResponse response, Exception e) {
        log.error(e)
        wsLogService.saveSmartPndLog([
                requestMethod  : request?.method,
                requestUrl     : request?.url,
                requestContent : request?.contentAsString,
                exception      : e,
                responseContent: response?.contentAsString])
    }
}
