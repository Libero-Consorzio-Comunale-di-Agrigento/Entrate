package it.finmatica.tr4.comunicazioni.payload

import grails.validation.Validateable
import it.finmatica.tr4.smartpnd.SmartPndService

@Validateable(nullable = true)
class InvioPNDPayload {
    String tag
    String oggetto
    String notificationFeePolicy
    String physicalCommunicationType
    ArrayList<DestinatarioPNDPayload> destinatari

    static constraints = {
        oggetto(minSize: 1, maxSize: SmartPndService.OGGETTO_PND_MAX_LENGTH)
    }

}
