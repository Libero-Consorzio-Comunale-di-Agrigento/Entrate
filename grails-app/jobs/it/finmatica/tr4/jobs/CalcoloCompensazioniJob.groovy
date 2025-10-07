package it.finmatica.tr4.jobs

import it.finmatica.afc.jobs.AfcElaborazioneService
import it.finmatica.afc.jobs.utility.AfcJobUtils
import it.finmatica.tr4.Compensazione
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.Soggetto
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.imposte.CompensazioniService
import it.finmatica.tr4.imposte.ImposteService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

class CalcoloCompensazioniJob {

    private static Log log = LogFactory.getLog(CalcoloCompensazioniJob)

    def grailsApplication
    ImposteService imposteService
    CompensazioniService compensazioniService
    CommonService commonService
    AfcElaborazioneService afcElaborazioneService
    ElaborazioniService elaborazioniService

    static triggers = {}

    def group = "CalcoloCompensazioniGroup"

    def description = "Calcolo compensazioni"

    def concurrent = false

    def numContribuentiSelezionati
    def numContribuentiTrattati
    def numContribuentiInErrore

    def execute(context) {
        log.info 'Inizio job [Calcolo compensazioni]'

        def lista = context.mergedJobDataMap.get("lista")
        def parametriCalcolo = context.mergedJobDataMap.get('parametriCalcolo')
        parametriCalcolo.codiceElaborazione = AfcJobUtils.getCodiceElaborazioneFromContext(context)

        log.info "Contribuenti da elaborare [${lista.size()}]"

        def logFile = this.getLogFile(context)
        logFile.write("")

        log.info("Creato file di log [${logFile.name}]")

        numContribuentiSelezionati = lista.size()
        numContribuentiTrattati = 0
        numContribuentiInErrore = 0


        def index = 1
        lista.each {

            def contribuente = Contribuente.findBySoggetto(Soggetto.get(it.key))
            parametriCalcolo.codFiscale = contribuente.codFiscale

            try {

                log.info("Elaborazione contribuente  [${contribuente.codFiscale} - ${index++} di ${lista.size()}]")

                def idCompensazione = compensazioniService.calcoloCompensazioni(parametriCalcolo)

                if (idCompensazione != null) {

                    numContribuentiTrattati++
                    Compensazione compensazione = Compensazione.get(idCompensazione)
                    def logString = "Generata compensazione per ${contribuente.soggetto.nome} ${contribuente.soggetto.cognome} codice fiscale ${contribuente.codFiscale} anno ${parametriCalcolo.anno} compensazione importo ${commonService.formattaValuta(compensazione.compensazione)}\n"
                    logFile.append(logString)

                } else {
                    numContribuentiInErrore++
                    logFile.append("Non generata compensazione per ${contribuente.soggetto.nome} ${contribuente.soggetto.cognome} codice fiscale ${contribuente.codFiscale} anno ${parametriCalcolo.anno}\n")
                }

            } catch (Exception e) {
                numContribuentiInErrore++
                e.printStackTrace()
                logFile.append("Errore in calcolo compensazioni per ${contribuente.soggetto.nome} ${contribuente.soggetto.cognome} codice fiscale ${contribuente.codFiscale} anno ${parametriCalcolo.anno} " + e.getMessage() + "\n")
            }
        }

        def resultLog = "Selezionati ${numContribuentiSelezionati}, trattati ${numContribuentiTrattati}, non trattati ${numContribuentiInErrore}.\n"
        logFile.append(resultLog)

        afcElaborazioneService.addLogPerContext(context, resultLog.replaceAll("\n", ""))

        log.info resultLog
        log.info 'Fine job [Calcolo compensazioni]'
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
