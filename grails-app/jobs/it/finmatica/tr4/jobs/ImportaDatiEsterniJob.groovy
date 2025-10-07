package it.finmatica.tr4.jobs

import it.finmatica.afc.jobs.AfcElaborazioneService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.datiesterni.DocumentoCaricato
import it.finmatica.tr4.datiesterni.ImportDatiEsterniService
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

class ImportaDatiEsterniJob {

    private static Log log = LogFactory.getLog(ImportaDatiEsterniJob)

    def grailsApplication
    ElaborazioniService elaborazioniService
    AfcElaborazioneService afcElaborazioneService
    ImportDatiEsterniService importDatiEsterniService
    Tr4AfcElaborazioneService tr4AfcElaborazioneService
    CommonService commonService

    static triggers = {}

    def group = "ImportaDatiEsterniGroup"

    def description = "Parsing dei file di dati esterni"

    def concurrent = false

    def execute(context) {

        log.info "Parte il job"
        def messaggio = ""

        try {
            def serviceBean = grailsApplication.mainContext.getBean(context.mergedJobDataMap.get('service'))
            def nomeMetodo = context.mergedJobDataMap.get('metodo')

            messaggio = serviceBean."${nomeMetodo}"(context.mergedJobDataMap.get('parametri'))

        } catch (Exception e) {
            afcElaborazioneService.addLogPerContext(context, e.message)
            importDatiEsterniService.cambiaStato(context.mergedJobDataMap.get('parametri').idDocumento, (short) 4)

            e.printStackTrace()
        }

        try {

            if (messaggio) {

                /**  Formato messaggio:
                 *   RIEPILOGO
                 *   <FINE_RIEPILOGO>
                 *   ELENCO_ERRORI
                 **/
                def splits = messaggio?.toString()?.split("<FINE_RIEPILOGO>")

                if (splits?.size() > 0) {
                    afcElaborazioneService.addLogPerContext(context, splits[0])

                    // Gestione errori
                    if (splits.size() == 2) {
                        tr4AfcElaborazioneService.createLogFile(context, 'error.log', splits[1]?.getBytes(), tr4AfcElaborazioneService.tipoLog.DATI_ESTERNI)
                    }

                } else {
                    afcElaborazioneService.addLogPerContext(context, "Importazione eseguita con successo.")
                }

            }
        } catch (Exception e) {
            log.error("Errore durante il salvataggio del report di caricamento", e)
            log.error("Messaggio: ${messaggio}")
        }
    }

    def logFile(def idDocumento) {

        def folder = commonService.toSnakeCase(DocumentoCaricato.get(idDocumento).titoloDocumento.descrizione)


        def fileSeparator = File.separator

        def logFolder = new File("${elaborazioniService.docFolder}$fileSeparator$folder")
        if (!logFolder.exists()) {
            logFolder.mkdir()
        }

        return new File("${logFolder.absolutePath}$fileSeparator${idDocumento}_log.txt")

    }
}

