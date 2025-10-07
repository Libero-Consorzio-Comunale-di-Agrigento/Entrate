package it.finmatica.tr4.reports

import document.FileNameGenerator
import grails.converters.JSON
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.wslog.WsLogService
import org.apache.log4j.Logger
import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService

import java.sql.Date
import java.text.SimpleDateFormat

class F24Controller {

    private static final Logger log = Logger.getLogger(F24Controller.class)

    F24Service f24Service
    JasperService jasperService

    WsLogService wsLogService

    def generaF24() {

        try {

            // Recupero del JSON
            def reqJSON = request.JSON

            // Controllo i parametri della richiesta
            def verifica = verificaRichiesta(reqJSON)

            if (!verifica.isValid) {

                // Se la richiesta contiene parametri non validi, viene segnalato l'errore
                def response = [
                        fileName    : "",
                        data        : "",
                        errorMessage: verifica.msg
                ]

                respond response, formats: ['json']

                wsLogService.savePortaleTrtibutiLog(
                        [
                                requestMethod  : request.method,
                                requestUrl     : request.forwardURI,
                                requestContent : (reqJSON as JSON).toString(true),
                                responseContent: (response as JSON).toString(true),
                        ]
                )

                return
            }

            def data = reqJSON.data ? (reqJSON.data as Map) : [:]
            data << [codFiscaleCoobbligato: reqJSON?.codFiscaleCoobbligato ?: "".padLeft(16, " ")]
            data << [codIdentificativo: reqJSON?.codIdentificativo ?: "".padLeft(2, " ")]

            // Genero il report
            def reportDef = generaFileF24(reqJSON.codFiscale,
                    reqJSON.tipoTributo,
                    reqJSON.anno,
                    reqJSON.tipoVersamento,
                    data)

            def f24file = jasperService.generateReport(reportDef)

            def fileName = FileNameGenerator.generateFileName(
                    FileNameGenerator.GENERATORS_TYPE.JASPER,
                    FileNameGenerator.GENERATORS_TITLES.F24,
                    [
                            codFiscale    : reqJSON.codFiscale,
                            anno          : reqJSON.anno,
                            tipoVersamento: reqJSON.tipoVersamento.charAt(0),
                            extension     : 'pdf'
                    ]
            )

            def response = [
                    fileName    : fileName,
                    data        : f24file.toByteArray().encodeBase64().toString(),
                    errorMessage: ""
            ]

            respond response, formats: ['json']

            wsLogService.savePortaleTrtibutiLog(
                    [
                            requestMethod  : request.method,
                            requestUrl     : request.forwardURI,
                            requestContent : (reqJSON as JSON).toString(true),
                            responseContent: (response as JSON).toString(true),
                    ]
            )

        } catch (Exception e) {

            e.printStackTrace()

            // Nel caso in cui la generazione del report non vada a buon fine.
            // Se si passa codice fiscale o anno non corretti (per esempio un codice fiscale che non esiste) oppure non è stato
            // eseguito il calcolo, la generazione va in errore all'interno di DatiF24ICI o DatiF24TASI o DatiF24UNICO

            def response = [
                    fileName    : "",
                    data        : "",
                    errorMessage: "Documento non generato: " + e.message + "\n" + e.stackTrace.join("\n")
            ]

            respond response, formats: ['json']

            wsLogService.savePortaleTrtibutiLog(
                    [
                            requestMethod  : request.method,
                            requestUrl     : request.forwardURI,
                            requestContent : (reqJSON as JSON).toString(true),
                            responseContent: (response as JSON).toString(true),
                            exception      : e
                    ]
            )
        }
    }

    private def generaFileF24(def codFiscale, def tipoTributo, def anno, def tipoVersamento, def data) {

        def tipoPag = tipoVersamento == "ACCONTO" ? 0 : (tipoVersamento == "SALDO" ? 1 : 2)

        if (tipoTributo == "TUTTI") {
            tipoTributo = "UNICO"
        }

        List f24data

        if (data == null) {
            f24data = f24Service.caricaDatiF24(codFiscale, tipoTributo, tipoPag, anno as short)
        } else {
            f24data = f24Service.caricaDatiF24(codFiscale, tipoTributo, tipoPag, anno as short, data)
        }

        JasperReportDef reportDef = new JasperReportDef(name: 'f24.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: f24data
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])

        return reportDef
    }

    private def verificaRichiesta(request) {

        // Controllo Tipo F24
        if (request?.tipoF24 == null) {
            return [isValid: false, msg: "Parametro 'tipoF24' mancante"]
        } else if (request.tipoF24 != "F24CI") {
            return [isValid: false, msg: "Tipo F24 errato"]
        }

        //Controllo Codice Fiscale
        if (request?.codFiscale == null) {
            return [isValid: false, msg: "Parametro 'codFiscale' mancante"]
        }

        // Controllo Tipo Tributo
        if (request?.tipoTributo == null) {
            return [isValid: false, msg: "Parametro 'tipoTributo' mancante"]
        } else if (request.tipoTributo != "ICI" && request.tipoTributo != "TASI" && request.tipoTributo != "TUTTI") {
            return [isValid: false, msg: "Tipo Tributo errato, possibili valori: 'ICI', 'TASI', 'TUTTI'"]
        }

        // Controllo Anno
        if (request?.anno == null) {
            return [isValid: false, msg: "Parametro 'anno' mancante"]
        } else if (request.anno < 0 || request.anno < 1900 || request.anno > 9999) {
            return [isValid: false, msg: "L'anno deve essere un numero valido"]
        }

        // Controllo Tipo Versamento
        if (request?.tipoVersamento == null) {
            return [isValid: false, msg: "Parametro 'tipoVersamento' mancante"]
        } else if (request.tipoVersamento != "ACCONTO" && request.tipoVersamento != "SALDO" && request.tipoVersamento != "UNICO") {
            return [isValid: false, msg: "Tipo Versamento errato, possibili valori: 'ACCONTO', 'SALDO', 'UNICO'"]
        }

        // Controllo esistenza pratica
        def existsPratica = f24Service.existsCalcoloIndividuale(request.tipoTributo, request.anno, request.codFiscale)

        if (!existsPratica) {
            def tipoTributoAttuale = TipoTributo.findByTipoTributo(request.tipoTributo).tipoTributoAttuale
            return [isValid: false, msg: "Posizione non trovata per [${request.codFiscale}, ${request.anno}, ${tipoTributoAttuale}]"]
        }


        def mappaDati = request?.data ? request.data[0] : null
        def errori

        if (mappaDati != null) {
            errori = controllaParametri(request.codFiscale, request.anno,
                    request.codFiscaleCoobbligato, request.codIdentificativo,
                    mappaDati as Map)
        }

        return errori ? [isValid: false, msg: errori] : [isValid: true, msg: ""]
    }


    private def controllaParametri(def codiceFiscale, def anno,
                                   def codFiscaleCoobbligato, def codIdentificativo,
                                   Map data) {


        if (codiceFiscale.length() != 11 && codiceFiscale.length() != 16) {
            return "Il parametro codiceFiscale non è corretto"
        }

        if (data?.codFiscaleCoobbligato && (data.codFiscaleCoobbligato.length() != 11 && data.codFiscaleCoobbligato.length() != 16)) {
            return "Il parametro codFiscaleCoobbligato non è corretto"
        }

        if (data?.codIdentificativo != null && data.codIdentificativo.length() != 2) {
            return "Il parametro codIdentificativo non è corretto"
        }

        // Controlli sui parametri presenti in data
        if (codFiscaleCoobbligato.startsWith("GUEST-")) {

            if (data?.soggettoCf != null && (data.soggettoCf.length() != 11 && data.soggettoCf.length() != 16)) {
                return "Il parametro soggettoCf non è corretto"
            }

            if (data?.soggettoDataNascita != null) {

                if (data.soggettoDataNascita.length() > 0 && data.soggettoDataNascita.length() < 8) {
                    return "Il parametro soggettoDataNascita non è corretto, deve essere nel formato DDMMYYY"
                }

                try {
                    def dataTemp = new Date(new SimpleDateFormat("ddMMyyyy")
                            .parse(data?.soggettoDataNascita).time)
                } catch (Exception e) {
                    return "Il parametro soggettoDataNascita non è corretto, deve essere nel formato DDMMYYY"
                }
            }

            if (data?.soggettoSesso != null && (data.soggettoSesso != 'M' && data.soggettoSesso != 'F')) {
                return "Il parametro soggettoSesso non è corretto, può solo assumere i valori 'M' o 'F'"
            }

            if (data?.soggettoProvNascita != null && data.soggettoProvNascita.length() != 2) {
                return "Il parametro provincia non è corretto"
            }

        }

        return ""
    }

}
