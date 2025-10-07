package it.finmatica.tr4.smartpnd

import grails.converters.JSON
import it.finmatica.tr4.smartpnd.handlers.*
import it.finmatica.tr4.wslog.WsLogService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.codehaus.groovy.grails.web.json.JSONObject

class SmartPNDController extends AuthRestfulController {

    private static Log log = LogFactory.getLog(SmartPNDController)

    WsLogService wsLogService

    static allowedMethods = [feedbackComunicazione: 'POST']

    def notifiche() {
        String plainRequestContent = getRequestContent()
        try {
            def jsonRequestContent = new JSONObject(plainRequestContent)
            log.info("Ricevuta notifica [${(jsonRequestContent as JSON).toString(true)}]")

            def handlerQueue = new ProtocolloCallbackHandler(user)
            handlerQueue.addCallbackHandler(new PecCallbackHandler(user))
            handlerQueue.addCallbackHandler(new PndCallbackHandler(user))
            handlerQueue.addCallbackHandler(new AnnullamentoCallbackHandler(user))
            handlerQueue.addCallbackHandler(new PndPriceCallbackHandler(user))

            def res = handlerQueue.manageRequest(jsonRequestContent)
            respond(res.response, status: res.status, formats: res.formats)

            wsLogService.saveSmartPndCallbackLog([
                    requestMethod  : request.method,
                    requestUrl     : request.forwardURI,
                    requestContent : (jsonRequestContent as JSON).toString(true),
                    *              : res.callbackLogHandlerDetails,
                    responseContent: (res.response as JSON).toString(true)])
        } catch (Exception e) {
            log.error('Errore', e)
            def res = [
                    response: [status: 'KO', error: e.getMessage()],
                    status  : 500,
                    formats : ['json']]
            respond(res.response, status: res.status, formats: res.formats)

            wsLogService.saveSmartPndCallbackLog([
                    requestMethod  : request.method,
                    requestUrl     : request.requestURL.toString(),
                    requestContent : plainRequestContent,
                    exception      : e,
                    responseContent: (res.response as JSON).toString(true)])
        }
    }

    private getRequestContent() {
        def plainRequestContent = ""
        request.reader.eachLine { line ->
            plainRequestContent += line
        }
        return plainRequestContent
    }
}
