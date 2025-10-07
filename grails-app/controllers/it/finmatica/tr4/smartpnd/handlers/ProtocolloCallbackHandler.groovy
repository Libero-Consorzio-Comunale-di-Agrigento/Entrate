package it.finmatica.tr4.smartpnd.handlers

import it.finmatica.tr4.smartpnd.ComunicazioneCallbackHandler
import org.apache.log4j.Logger

class ProtocolloCallbackHandler extends ComunicazioneCallbackHandler {

    private static final Logger log = Logger.getLogger(ProtocolloCallbackHandler.class)
    private static final String TIPO_CALLBACK_PROTOCOLLO = 'PROTOCOLLO'

    ProtocolloCallbackHandler(def user) {
        super(TIPO_CALLBACK_PROTOCOLLO, user)
    }

    @Override
    def elaboraComunicazione(def comunicazione) {

        log.info("Ricevute informazioni protocollo [${comunicazione.annoProto}, ${comunicazione.numeroProto}] ")

        def documentoContribuente = documentaleService.getDocumentoContribuenteByIdComunicazionePnd(comunicazione.idComunicazione)
        documentaleService.aggiornaProtocollo(documentoContribuente, comunicazione.annoProto, comunicazione.numeroProto)
    }
}
