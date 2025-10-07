package it.finmatica.tr4.jobs

import it.finmatica.afc.jobs.AfcElaborazioneService
import it.finmatica.tr4.supportoservizi.SupportoServiziService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

class SupportoServiziJob {

    private static Log log = LogFactory.getLog(SupportoServiziJob)

    AfcElaborazioneService afcElaborazioneService
    SupportoServiziService supportoServiziService

    static triggers = {}

    def group = "SupportoServiziJob"

    def description = "Bonifiche per contribuente"

    def concurrent = false

    def execute(context) {

        log.info 'Inizio job Bonifiche per contribuente'

        String utenteBatch = context.mergedJobDataMap.get('codiceUtenteBatch')

        String operazione = context.mergedJobDataMap.get('operazione')
        def parametri = context.mergedJobDataMap.get('parametri')

        log.info "Eseguo '${operazione}'"

        try {
            String message = ""
            def report = [
                    retuls : 0,
                    message: '',
            ]

            switch (operazione) {
                case 'popolaSupporto':
                    report = supportoServiziService.popolaSupporto(parametri, utenteBatch)
                    break
                case 'assegnazioneContribuenti':
                    report = supportoServiziService.assegnazioneContribuenti(parametri)
                    break
                case 'aggiornaAssegnazione':
                    report = supportoServiziService.aggiornaAssegnazione(parametri)
                    break
                default:
                    throw new Exception("SupportoServiziJob : Operazione sconosciuta (${operazione})")
            }
            if (report.result == 0) {
                message = "Operazione eseguita : ${report.message}"
            } else {
                message = "Errore durante l'operazione : ${report.message}"
            }

            afcElaborazioneService.addLogPerContext(context, message)
            log.info "${message}"

        } catch (Exception e) {
            afcElaborazioneService.addLogPerContext(context, e.message)
            e.printStackTrace()
            log.info "Errore durante l'operazione : " + e.getMessage()
            throw e
        }
    }
}
