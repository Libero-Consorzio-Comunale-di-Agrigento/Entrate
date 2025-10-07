package it.finmatica.tr4.reports

import grails.converters.JSON
import it.finmatica.tr4.commons.TipoPratica
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.wslog.WsLogService
import org.apache.log4j.Logger
import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService

class F24PraticaController {

    private static final Logger log = Logger.getLogger(F24PraticaController.class)

    F24Service f24Service
    JasperService jasperService
    WsLogService wsLogService
    def prtr

    def generaF24() {

        // Recupero del JSON
        def reqJSON = request.JSON

        try {

            // Controllo i parametri della richiesta
            def verifica = verificaRichiesta(reqJSON)

            if (!verifica.isValid) {
                // Se la richiesta contiene parametri non validi, viene segnalato l'errore
                def response = [
                        fileName    : "",
                        data        : "",
                        errorMessage: verifica.msg
                ]

                respond response, formats: ['json'], status: 400

                wsLogService.savePortaleTrtibutiLog([
                        requestMethod  : request.method,
                        requestUrl     : request.forwardURI,
                        requestContent : (reqJSON as JSON).toString(true),
                        responseContent: (response as JSON).toString(true),
                ])

                return
            }

            def data = reqJSON.data ? (reqJSON.data as Map) : [:]
            def response = [
                    fileName    : "F24.pdf",
                    data        : generaFileF24Violazione((data.importoRidotto ?: "S") == "S"),
                    errorMessage: ""
            ]

            respond response, formats: ['json']

            wsLogService.savePortaleTrtibutiLog([
                    requestMethod : request.method,
                    requestUrl    : request.forwardURI,
                    requestContent: (reqJSON as JSON).toString(true),
                    responseContent: (response as JSON).toString(true),
            ])

        } catch (Exception e) {
            e.printStackTrace()

            def response = [
                    fileName    : "",
                    data        : "",
                    errorMessage: "Documento non generato: " + e.message + "\n" + e.stackTrace.join("\n")
            ]

            respond response, formats: ['json'], status: 500

            wsLogService.savePortaleTrtibutiLog([
                    requestMethod : request.method,
                    requestUrl    : request.forwardURI,
                    requestContent: (reqJSON as JSON).toString(true),
                    responseContent: (response as JSON).toString(true),
                    exception     : e
            ])
        }
    }

    private def verificaRichiesta(request) {
        // Verifica la presenza del parametro 'idPratica' nella richiesta
        if (request?.idPratica == null) {
            return [isValid: false, msg: "Parametro 'idPratica' mancante"]
        }

        // Verifica che il parametro 'idPratica' sia un numero valido
        if (!(request.idPratica instanceof Number)) {
            return [isValid: false, msg: "Parametro 'idPratica' non valido"]
        }

        prtr = PraticaTributo.get(request.idPratica as Long)
        // Verifica l'esistenza della pratica
        if (!prtr) {
            return [isValid: false, msg: "Pratica non trovata"]
        }

        if (!['ICI', 'TARSU'].contains(prtr.tipoTributo.tipoTributo)) {
            return [isValid: false, msg: "Tipo '${prtr.tipoTributo.getTipoTributoAttuale()}' non supportato"]
        }

        if (prtr.anno < 2012 && prtr.tipoTributo.tipoTributo == 'ICI') {
            return [isValid: false, msg: "Per le pratiche IMU l'anno deve essere maggiore o uguale a 2012"]
        }

        // Verifica il tipo di pratica
        if (![TipoPratica.L.tipoPratica, TipoPratica.A.tipoPratica, TipoPratica.V.tipoPratica].contains(prtr.tipoPratica)) {
            return [isValid: false, msg: "Tipo pratica '${prtr.tipoPratica}' non supportato"]
        }

        // Verifica se il parametro 'importoRidotto' è presente e se ha un valore valido
        if (request?.importoRidotto != null && !['S', 'N'].contains(request.importoRidotto)) {
            return [isValid: false, msg: "Parametro 'importoRidotto' non valido. Deve essere 'S' o 'N'."]
        }

        return [isValid: true]
    }

    private def generaFileF24Violazione(def ridotto) {

        List f24data
        def reportDef

        f24data = f24Service.caricaDatiF24(prtr, 'V', ridotto)

        if (f24data) {
            reportDef = new JasperReportDef(name: 'f24.jasper'
                    , fileFormat: JasperExportFormat.PDF_FORMAT
                    , reportData: f24data
                    , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/"])

            return jasperService.generateReport(reportDef).toByteArray().encodeBase64().toString()

        }
    }
}
