package it.finmatica.tr4.jobs

import it.finmatica.afc.jobs.utility.AfcJobUtils
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.pratiche.PraticaTributo
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.codehaus.groovy.grails.plugins.DomainClassGrailsPlugin
import org.quartz.JobExecutionContext

class AssegnaStatoTipoAttoJob {

    private static Log log = LogFactory.getLog(AssegnaStatoTipoAttoJob)

    def sessionFactory
    def propertyInstanceMap = DomainClassGrailsPlugin.PROPERTY_INSTANCE_MAP
    ElaborazioniService elaborazioniService
    def afcElaborazioneService


    static triggers = {}

    def group = "Massive pratiche"

    def description = "Assegna Stato/Tipo Atto"

    def concurrent = false

    def execute(context) {
        def stato = context.mergedJobDataMap.get('stato')
        def tipoAtto = context.mergedJobDataMap.get('tipoAtto')
        def pratiche = context.mergedJobDataMap.get('pratiche')
        def utente = context.mergedJobDataMap.get('codiceUtenteBatch')

        def logFile = inizializzaLog(context)

        def newStato = stato?.toDomain()
        def newTipoAtto = tipoAtto?.toDomain()

        def msg = "Assegnazione Stato/Tipo Atto ${newStato?.descrizione ?: '<Non selezionato>'} / ${newTipoAtto?.descrizione ?: '<Non selezionato>'} per ${pratiche.size()} pratiche."
        log.info(msg)
        logFile.append("$msg\n")

        def index = 0
        pratiche.each {
            def pratica = PraticaTributo.get(it)
            logFile.append("[ Codice Fiscale : ${pratica.contribuente.codFiscale}, Pratica: ${pratica.id}, Tipo pratica: ${pratica.tipoPratica}, Numero : ${pratica.numero}, Anno : ${pratica.anno}, Data : ${pratica.data}, Stato precedente: ${pratica?.tipoStato?.descrizione ?: ''}, Tipo Atto precedente: (${pratica?.tipoAtto?.tipoAtto ?: ''}) - ${pratica?.tipoAtto?.descrizione ?: ''}]\n")
            pratica.tipoStato = newStato ?: pratica.tipoStato
            pratica.tipoAtto = newTipoAtto ?: pratica.tipoAtto
            pratica.utente = utente
            try {
                pratica.save(failOnError: true, flush: true)
            } catch (Exception e) {
                e.printStackTrace()
                log.error(e)
                logFile.append("Errore durante l'assegnazione Stato/Tipo Atto: ${e.message}\n")
            }

            if (++index % 100 == 0) {
                cleanUpGorm()
            }
        }

        afcElaborazioneService.addLogPerContext(context, "Elaborazione eseguita con successo")
    }

    private def cleanUpGorm() {
        def session = sessionFactory.currentSession
        session.flush()
        session.clear()
        propertyInstanceMap.get().clear()
    }

    private File inizializzaLog(JobExecutionContext context) {

        log.info("Inizio job [" + description + "]")

        def logFile = this.getLogFile(context)
        logFile.write("")

        log.info("Creato file di log [${logFile.name}]")

        return logFile
    }

    private def getLogFile(def context) {
        def folder = "Elaborazioni"
        def fileSeparator = File.separator

        def logFolder = new File("${elaborazioniService.docFolder}$fileSeparator$folder")
        if (!logFolder.exists()) {
            logFolder.mkdir()
        }

        def nomeFile = AfcJobUtils.getCodiceElaborazioneFromContext(context)

        return new File("${logFolder.absolutePath}$fileSeparator${nomeFile}.log")
    }
}
