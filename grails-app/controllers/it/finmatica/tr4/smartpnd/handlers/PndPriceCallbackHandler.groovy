package it.finmatica.tr4.smartpnd.handlers

import it.finmatica.tr4.smartpnd.ComunicazioneCallbackHandler
import org.apache.log4j.Logger

class PndPriceCallbackHandler extends ComunicazioneCallbackHandler {

    private static final Logger log = Logger.getLogger(PndPriceCallbackHandler.class)
    private static final String TIPO_CALLBACK_PND_PRICE = 'PND_PRICE'

    PndPriceCallbackHandler(def user) {
        super(TIPO_CALLBACK_PND_PRICE, user)
    }

    @Override
    def elaboraComunicazione(def comunicazione) {

        log.info("Ricevute informazioni PND Price [${comunicazione.costo}] ")

        documentaleService.aggiornaCostoPnd(comunicazione.idComunicazione, comunicazione.costo, user)
    }
}
