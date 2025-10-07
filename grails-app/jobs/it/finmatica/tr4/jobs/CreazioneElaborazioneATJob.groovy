package it.finmatica.tr4.jobs


import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

class CreazioneElaborazioneATJob {

    private static Log log = LogFactory.getLog(CreazioneElaborazioneATJob)

    ElaborazioniService elaborazioniService
    CommonService commonService

    static triggers = {}

    def group = "ElaborazioniMassiveGroup"

    def description = "Creazione elaborazione"

    def concurrent = false

    def execute(context) {

        def nomeElaborazione = context.mergedJobDataMap.get('nomeElaborazione')
        def idElaborazioneDaCopiare = context.mergedJobDataMap.get('idElaborazioneDaCopiare')

        def utente = context.mergedJobDataMap.get('codiceUtenteBatch')

        log.info("Avvio creazione elaborazione massiva AT.")

        try {

            def elab = null

            def execTime = commonService.timeMe {
                elab = elaborazioniService.creaElaborazione(
                        [
                                nomeElaborazione: nomeElaborazione,
                                tipoTributo     : tipoTributo,
                                tipoPratica     : tipoPratica,
                                ruolo           : ruolo,
                                anno            : anno,
                                utente          : utente
                        ],
                        dettagli,
                        creaElaborazioniSeparate ?: false,
                        creaElaborazioniAAT ?: false,
                        selectAllDetails
                )
            }


        } catch (Exception e) {
            e.printStackTrace()
        }
    }
}
