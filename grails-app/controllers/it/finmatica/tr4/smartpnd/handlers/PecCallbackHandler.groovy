package it.finmatica.tr4.smartpnd.handlers

import it.finmatica.tr4.dto.comunicazioni.TipiCanaleDTO
import it.finmatica.tr4.smartpnd.ComunicazioneCallbackHandler
import org.apache.log4j.Logger

import java.text.SimpleDateFormat

class PecCallbackHandler extends ComunicazioneCallbackHandler {

    private static final Logger log = Logger.getLogger(PecCallbackHandler.class)
    private static final String TIPO_CALLBACK_PEC = 'RICEVUTE_PEC'

    static String PEC_DATA_FORMAT = 'dd/MM/yyyy HH:mm:ss'

    PecCallbackHandler(def user) {
        super(TIPO_CALLBACK_PEC, user)
    }

    @Override
    def elaboraComunicazione(def comunicazione) {

        def documentoContribuente = documentaleService.getDocumentoContribuenteByIdComunicazionePnd(comunicazione.idComunicazione)
        def dataSpedizione = comunicazione.dataSpedizione ? new SimpleDateFormat(PEC_DATA_FORMAT).parse(comunicazione.dataSpedizione) : null
        def dataAccettazione = comunicazione.dataAccettazione ? new SimpleDateFormat(PEC_DATA_FORMAT).parse(comunicazione.dataAccettazione) : null
        log.info("Ricevute informazioni PEC [${dataSpedizione}, ${dataAccettazione}]")

        documentaleService.aggiornaInvio(documentoContribuente, dataSpedizione, dataAccettazione, 1L, user, TipiCanaleDTO.PEC)

    }
}
