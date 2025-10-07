package it.finmatica.tr4.smartpnd.handlers

import it.finmatica.tr4.dto.comunicazioni.TipiCanaleDTO
import it.finmatica.tr4.smartpnd.ComunicazioneCallbackHandler
import org.apache.log4j.Logger

import java.text.SimpleDateFormat

class PndCallbackHandler extends ComunicazioneCallbackHandler {

    private static final Logger log = Logger.getLogger(PndCallbackHandler.class)
    private static final String TIPO_CALLBACK_PND = 'PND'

    static String PND_DATA_FORMAT = 'dd/MM/yyyy HH:mm:ss'

    PndCallbackHandler(def user) {
        super(TIPO_CALLBACK_PND, user)
    }

    @Override
    def elaboraComunicazione(def comunicazione) {

        log.info("Comunicazione [$comunicazione.idComunicazione] status: [$comunicazione.status]")
        log.debug("Comunicazione [$comunicazione.idComunicazione] dataStatus: [$comunicazione.dataStatus]")
        log.debug("Comunicazione [$comunicazione.idComunicazione] channel: [$comunicazione.channel]")

        def final tipiNotificaPND = [
                APPIO                   : 81,
                SMS                     : 82,
                EMAIL                   : 83,
                PEC                     : 84,
                AR_REGISTERED_LETTER    : 85,
                REGISTERED_LETTER_890   : 86,
                SIMPLE_REGISTERED_LETTER: 87
        ]

        def documentoContribuente = documentaleService.getDocumentoContribuenteByIdComunicazionePnd(comunicazione.idComunicazione)
        def dataSpedizione = comunicazione.status in ['VIEWED', 'DELIVERED'] ? new SimpleDateFormat(PND_DATA_FORMAT).parse(comunicazione.dataStatus) : null
        def stato = comunicazione.status
        def tipoNotifica = comunicazione.channel ? tipiNotificaPND[comunicazione.channel] : null

        if (comunicazione.channel != "null" && !tipoNotifica) {
            throw new RuntimeException("Comunicazione [$comunicazione.idComunicazione] channel: [$comunicazione.channel] non riconosciuto")
        }

        log.info("Ricevute informazioni PND [$dataSpedizione, $stato]")

        documentaleService.aggiornaInvio(documentoContribuente, dataSpedizione, stato, tipoNotifica, user, TipiCanaleDTO.PND)


    }
}
