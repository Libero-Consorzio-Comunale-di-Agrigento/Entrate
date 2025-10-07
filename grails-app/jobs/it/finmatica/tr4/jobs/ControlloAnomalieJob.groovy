package it.finmatica.tr4.jobs

import it.finmatica.afc.jobs.AfcElaborazioneService
import it.finmatica.tr4.bonificaDati.ControlloAnomalieService
import it.finmatica.tr4.dto.anomalie.TipoAnomaliaDTO
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

class ControlloAnomalieJob {

    private static Log log = LogFactory.getLog(ControlloAnomalieJob)

    def grailsApplication
    ControlloAnomalieService controlloAnomalieService
    AfcElaborazioneService afcElaborazioneService

    static triggers = {}

    def group = "ControlloAnomalieGroup"

    def description = "Controllo anomalie su oggetti e dichiarazioni"

    def concurrent = false

    def execute(context) {
        log.info "*****************"
        log.info "Eseguo " + context.mergedJobDataMap.get('customDescrizioneJob')
        TipoAnomaliaDTO tipoAnomalia = context.mergedJobDataMap.get('tipoAnomalia')
        long idAnomaliaParametro = context.mergedJobDataMap.get('idAnomaliaParametro')
        Map parametri = context.mergedJobDataMap.get('parametri')
        log.info parametri
        String messaggio = ""
        try {
            messaggio = controlloAnomalieService."${tipoAnomalia.nomeMetodo}"(parametri)
        } catch (Exception e) {
            e.printStackTrace()
            log.info "Errore in controllo anomalia ${tipoAnomalia.tipoAnomalia} " + e.getMessage()
            //afcElaborazioneService.addLogPerContext(context, "Errore in controllo anomalia ${tipoAnomalia.tipoAnomalia} " + e.getMessage())
            throw e
        } finally {
            log.info "Unlock " + idAnomaliaParametro
            controlloAnomalieService.unlockControlloAnomalia(idAnomaliaParametro)
        }
        afcElaborazioneService.addLogPerContext(context, messaggio)
    }
}
