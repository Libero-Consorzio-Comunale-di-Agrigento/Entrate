package it.finmatica.tr4.jobs


import it.finmatica.afc.jobs.AfcElaborazioneService
import it.finmatica.afc.jobs.utility.AfcJobUtils
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.imposte.ImposteService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.quartz.JobExecutionContext

class CalcoloLiquidazioniJob {

    private static Log log = LogFactory.getLog(CalcoloLiquidazioniJob)

    def grailsApplication
    ImposteService imposteService
    ElaborazioniService elaborazioniService
    AfcElaborazioneService afcElaborazioneService

    static triggers = {}

    def group = "CalcoloLiquidazioni"
    def description = "Calcolo liquidazioni"

    def concurrent = false


    def execute(JobExecutionContext context) {
        def logFile = inizializzaLog(context)

        doExecute(logFile, context)

        finalizzaLog(logFile, context)
    }


    private File inizializzaLog(JobExecutionContext context) {

        log.info("Inizio job [" + description + "]")

        def logFile = this.getLogFile(context)
        logFile.write("")

        log.info("Creato file di log [${logFile.name}]")

        return logFile
    }

    private def finalizzaLog(File logFile, JobExecutionContext context) {

        log.info("Fine job [" + description + "]")
    }

    private def doExecute(def logFile, JobExecutionContext context) {

        def parametriCalcolo = context.mergedJobDataMap.get('parametriCalcolo')
        parametriCalcolo.codiceElaborazione = AfcJobUtils.getCodiceElaborazioneFromContext(context)
        def user = context.mergedJobDataMap.get('codiceUtenteBatch')

        try {
            def contatore = imposteService.calcoloLiquidazioni(parametriCalcolo, user)

            def msg = (contatore > 0)
                    ? "Attenzione non è stato possibile effettuare la liquidazione per ${contatore} Contribuente/i\n"
                    : "Elaborazione conclusa.\n"

            logFile.append(msg)
            if (contatore > 0) {
                Collection contribuentiNonLiquidati = imposteService.contribuentiNonLiquidati(parametriCalcolo.tributo) as Collection
                logFile.append("Sono stati trovati ${contribuentiNonLiquidati.size()} non liquidati\n")
                contribuentiNonLiquidati.each {
                    logFile.append("[ Codice Fiscale : ${it.COD_FIS}, Nome : ${it.NOME}, Anno : ${it.ANNO}, Data : ${it.DATA}, Note : ${it.NOTE_CALCOLO ?: ""} ]\n")
                }
            }

            afcElaborazioneService.addLogPerContext(context, "Elaborazione eseguita con successo")
        } catch (Exception e) {
            e.printStackTrace()
            logFile.append("Errore in calcolo liquidazione" + e.getMessage() + "\n")
        }
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
