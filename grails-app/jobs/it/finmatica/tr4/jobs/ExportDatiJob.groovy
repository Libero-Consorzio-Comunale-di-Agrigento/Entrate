package it.finmatica.tr4.jobs

import it.finmatica.afc.jobs.AfcElaborazioneService
import it.finmatica.tr4.datiesterni.ExportDatiService
import it.finmatica.tr4.dto.ParametriExportDTO
import org.quartz.JobExecutionContext

class ExportDatiJob {
    ExportDatiService exportDatiService
    AfcElaborazioneService afcElaborazioneService
    Tr4AfcElaborazioneService tr4AfcElaborazioneService

    static triggers = {}

    def concurrent = false

    def group = "ExportDatiJob"
    def description = "Esportazione dati"

    def execute(JobExecutionContext context) {
        def tipoExport = context.mergedJobDataMap.get("tipoExport")
        def paramsIn = context.mergedJobDataMap.get("paramsIn")
        def listaParametriExport = context.mergedJobDataMap.get("listaParametriExport")

        def result = exportDatiService.eseguiExport(
                tipoExport.nomeProcedura,
                tipoExport,
                paramsIn,
                listaParametriExport
        )

        addLogFile(context, result)

        Collection<ParametriExportDTO> outputParameters = listaParametriExport.findAll { it.tipoParametro == 'U' }
        addLogMessage(context, result, outputParameters)

    }

    private void addLogMessage(JobExecutionContext context, def result, Collection<ParametriExportDTO> outputParameters) {
        String logMessage = ""

        if (result.time) {
            logMessage += "Esportazione eseguita in ${result.time}\n"
        }

        if (result.output) {
            result.output.eachWithIndex { it, i ->
                logMessage += "${outputParameters.getAt(i)?.nomeParametro}: ${it}\n"
            }
        }

        afcElaborazioneService.addLogPerContext(context, logMessage)
    }

    private void addLogFile(JobExecutionContext context, def result) {
        if (result.data) {
            tr4AfcElaborazioneService.createLogFile(context, result.nomeFile, result.data.bytes, tr4AfcElaborazioneService.tipoLog.DATI_ESTERNI)
        }
    }
}
