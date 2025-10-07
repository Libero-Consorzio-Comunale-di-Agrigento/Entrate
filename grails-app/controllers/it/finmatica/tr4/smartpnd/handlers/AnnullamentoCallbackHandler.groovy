package it.finmatica.tr4.smartpnd.handlers

import it.finmatica.tr4.smartpnd.ComunicazioneCallbackHandler
import org.apache.log4j.Logger

class AnnullamentoCallbackHandler extends ComunicazioneCallbackHandler {

    private static final Logger log = Logger.getLogger(AnnullamentoCallbackHandler.class)
    private static final String TIPO_CALLBACK_ANNULLAMENTO = 'ELIMINAZIONE'

    AnnullamentoCallbackHandler(def user) {
        super(TIPO_CALLBACK_ANNULLAMENTO, user)
    }

    @Override
    def elaboraComunicazione(def comunicazione) {
        def documentoContribuente = documentaleService.getDocumentoContribuenteByIdComunicazionePnd(comunicazione.idComunicazione)
        log.info("Eliminazione comunicazione [${comunicazione.idComunicazione}]")

        documentaleService.annullaDocumento(documentoContribuente)
    }
}
