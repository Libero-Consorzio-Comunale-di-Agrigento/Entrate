package it.finmatica.tr4.comunicazioni.payload

import it.finmatica.tr4.smartpnd.SmartPndService

class InvioAppIOPayload {
    String tag
    String codFiscale
    String oggetto
    String testo
    String importo
    String flagScadenza
    String codiceAvviso
    String dataScadenza
    String dataPagamento
    String richiestaPagamento

    static constraints = {
        oggetto(minSize: SmartPndService.OGGETTO_APPIO_MIN_LENGTH,
                maxSize: SmartPndService.OGGETTO_APPIO_MAX_LENGTH)
        testo(minSize: SmartPndService.CONTENUTO_APPIO_MIN_LENGTH,
                maxSize: SmartPndService.CONTENUTO_APPIO_MAX_LENGTH)
    }
}
