package it.finmatica.tr4.jobs


import it.finmatica.afc.jobs.AfcElaborazioneService
import it.finmatica.afc.jobs.utility.AfcJobUtils
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.Soggetto
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.imposte.ImposteService
import it.finmatica.tr4.pratiche.PraticaTributo
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.quartz.JobExecutionContext

class CalcoloSollecitiJob {

    private static Log log = LogFactory.getLog(CalcoloSollecitiJob)

    def grailsApplication
    ImposteService imposteService
    AfcElaborazioneService afcElaborazioneService
    ElaborazioniService elaborazioniService
    CommonService commonService

    static triggers = {}

    def group = "CalcoloSolleciti"
    def description = "Calcolo solleciti"

    def concurrent = false

    def numContribuentiSelezionati
    def numContribuentiTrattati
    def numContribuentiInErrore

    def execute(JobExecutionContext context) {

        log.info("Inizio job [" + description + "]")

        def lista = context.mergedJobDataMap.get("listaContribuenti")

        if (lista) {
            executeWithListaContribuenti(context, lista)
        } else {
            executeWithoutListaContribuenti(context)
        }

        log.info("Fine job [" + description + "]")
    }


    private File inizializzaLog(JobExecutionContext context) {

        log.info("Inizio job [" + description + "]")

        def logFile = this.getLogFile(context)
        logFile.write("")

        log.info("Creato file di log [${logFile.name}]")

        return logFile
    }

    private def executeWithoutListaContribuenti(JobExecutionContext context) {
        log.info 'Calcolo Solleciti senza lista contribuenti'

        def parametriCalcolo = context.mergedJobDataMap.get('parametriCalcolo')
        parametriCalcolo.codiceElaborazione = AfcJobUtils.getCodiceElaborazioneFromContext(context)
        def user = context.mergedJobDataMap.get('codiceUtenteBatch')

        try {
            imposteService.calcoloSolleciti(parametriCalcolo, user)
            afcElaborazioneService.addLogPerContext(context, "Elaborazione eseguita con successo")
            log.info('Elaborazione eseguita con successo')
        } catch (Exception e) {
            afcElaborazioneService.addLogPerContext(context, e.message)
            e.printStackTrace()
        }
    }

    private def executeWithListaContribuenti(JobExecutionContext context, def listaContribuenti) {
        def logFile = inizializzaLog(context)

        numContribuentiTrattati = 0
        numContribuentiInErrore = 0
        numContribuentiSelezionati = listaContribuenti.size()

        log.info 'Calcolo Solleciti da lista contribuenti'

        def parametriCalcolo = context.mergedJobDataMap.get('parametriCalcolo')
        parametriCalcolo.codiceElaborazione = AfcJobUtils.getCodiceElaborazioneFromContext(context)
        def user = context.mergedJobDataMap.get('codiceUtenteBatch')
        def contribuentiProps = context.mergedJobDataMap.get('contribuentiProps')

        log.info "Contribuenti da elaborare [${listaContribuenti.size()}]"

        def index = 1
        listaContribuenti.each {

            def contribuente = Contribuente.findBySoggetto(Soggetto.get(it.key))
            parametriCalcolo.codFiscale = contribuente.codFiscale

            if (contribuentiProps != null) {
                def ruolo = contribuentiProps.get(it.key)?.ruolo
                parametriCalcolo.ruolo = ruolo != null ? ruolo : 0
            }
            try {
                log.info("Elaborazione contribuente [${contribuente.codFiscale} - ${index++} di ${listaContribuenti.size()}]")

                def idPratica = imposteService.calcoloSolleciti(parametriCalcolo, user)

                if (idPratica != null) {
                    numContribuentiTrattati++
                    PraticaTributo pratica = PraticaTributo.get(idPratica)
                    def logString = "Generato sollecito per ${contribuente.soggetto.nome} ${contribuente.soggetto.cognome} codice fiscale ${contribuente.codFiscale} anno ${parametriCalcolo.anno} importo ${commonService.formattaValuta(pratica.importoTotale)}\n"
                    logFile.append(logString)
                } else {
                    numContribuentiInErrore++
                    logFile.append("Non generato sollecito per ${contribuente.soggetto.nome} ${contribuente.soggetto.cognome} codice fiscale ${contribuente.codFiscale} anno ${parametriCalcolo.anno}\n")
                }
            } catch (Exception e) {
                numContribuentiInErrore++
                e.printStackTrace()
                logFile.append("Errore in generazione sollecito per ${contribuente.soggetto.nome} ${contribuente.soggetto.cognome} codice fiscale ${contribuente.codFiscale} anno ${parametriCalcolo.anno}: " + e.getMessage() + "\n")
            }
        }

        def resultLog = "Selezionati ${numContribuentiSelezionati}, trattati ${numContribuentiTrattati}, non trattati ${numContribuentiInErrore}.\n"
        logFile.append(resultLog)

        afcElaborazioneService.addLogPerContext(context, resultLog.replaceAll("\n", ""))
        log.info resultLog
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
