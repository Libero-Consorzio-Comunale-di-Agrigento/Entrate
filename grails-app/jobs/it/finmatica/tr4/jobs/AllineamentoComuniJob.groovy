package it.finmatica.tr4.jobs


import it.finmatica.tr4.soggetti.SoggettiService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

class AllineamentoComuniJob {

    private static Log log = LogFactory.getLog(AllineamentoComuniJob)

    SoggettiService soggettiService

    static triggers = {}

    def group = "AllineamentoComuni"
    def description = "Allineamento comuni"

    def concurrent = false

    def execute(context) {
        log.info 'Inizio job [Allineamento Comuni]'

        try {
            soggettiService.allineamentoComuni()
        } catch (Exception e) {
            log.info 'Errore job [Allineamento Comuni]'
            e.printStackTrace()
            throw e
        }

        log.info 'Fine job [Allineamento Comuni]'
    }
}
