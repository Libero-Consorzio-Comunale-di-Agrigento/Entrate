package it.finmatica.tr4.smartpnd


import grails.util.Holders
import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.documentale.DocumentaleService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

abstract class ComunicazioneCallbackHandler implements CallbackHandler {

    private static Log log = LogFactory.getLog(ComunicazioneCallbackHandler)

    def user
    private ComunicazioneCallbackHandler nextHandler
    private String tipoCallback


    DatiGeneraliService datiGeneraliService
    DocumentaleService documentaleService

    ComunicazioneCallbackHandler(String tipoCallback, def user) {
        this.tipoCallback = tipoCallback
        this.user = user
    }

    void addCallbackHandler(ComunicazioneCallbackHandler nextHandler) {
        if (this.nextHandler) {
            this.nextHandler.addCallbackHandler(nextHandler)
            return
        }
        this.nextHandler = nextHandler
    }

    @Override
    def manageRequest(def comunicazione) {

        log.info("${this.class.name}: Elaborazione callback...")

        datiGeneraliService = (DatiGeneraliService) Holders.grailsApplication.mainContext
                .getBean("datiGeneraliService")

        documentaleService = (DocumentaleService) Holders.grailsApplication.mainContext
                .getBean("documentaleService")

        def result = [
                response: [
                        idComunicazione: comunicazione.idComunicazione,
                        status         : 'OK',
                        error          : ''],
                status  : 200,
                formats                  : ['json'],
                callbackLogHandlerDetails: [tipoCallback   : tipoCallback,
                                            idComunicazione: comunicazione.idComunicazione]
        ]
        try {

            def tipoCallbackComunicazione = comunicazione.tipoCallback
            if (!tipoCallbackComunicazione) {
                throw new IllegalArgumentException("tipoCallback obbligatorio")
            }
            if (tipoCallback != tipoCallbackComunicazione) {
                if (this.nextHandler) {
                    return this.nextHandler.manageRequest(comunicazione)
                }

                throw new Exception("Nessun handler disponibile per il tipoCallback $tipoCallbackComunicazione")
            }

            def valida = verificaComunicazione(comunicazione)
            if (valida) {
                log.info("Callback non valida: $valida")
                return valida
            }

            elaboraComunicazione(comunicazione)

            log.info("Callback elaborata: $result")

            return result
        } catch (Exception e) {
            log.error('Impossibile gestire Callback', e)

            result.response.status = 'KO'
            result.response.error = e.getMessage()
            result.status = 500

            result.callbackLogHandlerDetails.exception = e

            return result
        }
    }

    abstract elaboraComunicazione(def comunicazione)

    private def verificaComunicazione(def comunicazione) {
        def result = [
                response: [
                        idComunicazione: comunicazione.idComunicazione,
                        status         : 'KO'
                ],
                formats : ['json']
        ]

        if (comunicazione.applicativo != SmartPndService.APPLICATIVO_TR4) {

            result.response.error = "Proprietà 'applicativo' ${comunicazione.applicativo} non valida"
            result.status = 400

            return result
        }


        def documentoContribuente = documentaleService.getDocumentoContribuenteByIdComunicazionePnd(comunicazione.idComunicazione)
        if (!documentoContribuente) {
            result.response.error = "Documento contribuente non trovato per l'idComunicazione ${comunicazione.idComunicazione}"
            result.status = 400

            return result
        }

    }
}
