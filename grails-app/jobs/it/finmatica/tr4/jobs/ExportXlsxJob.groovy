package it.finmatica.tr4.jobs

import it.finmatica.afc.jobs.AfcElaborazioneService
import it.finmatica.tr4.datiesterni.ExportDatiService
import it.finmatica.tr4.dto.ParametriExportDTO
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.export.XlsxExporter
import org.quartz.JobExecutionContext

class ExportXlsxJob {

    AfcElaborazioneService afcElaborazioneService
    Tr4AfcElaborazioneService tr4AfcElaborazioneService

    static triggers = {}

    def concurrent = false

    def group = "ExportXlsxJob"
    def description = "Esportazione XLSX"

    def execute(JobExecutionContext context) {

        try {

            def fileName = context.mergedJobDataMap.get("fileName")
            def listGenerator = context.mergedJobDataMap.get("listGenerator")
            def fields = context.mergedJobDataMap.get("fields")
            def converters = context.mergedJobDataMap.get("converters")
            def bigDecimalFormats = context.mergedJobDataMap.get("bigDecimalFormats")
            def dateFormats = context.mergedJobDataMap.get("dateFormats")

            def lista = listGenerator.call()

            def xlsx = XlsxExporter.generaXlsx(fileName, lista, fields, converters, bigDecimalFormats, dateFormats)

            afcElaborazioneService.addLogPerContext(context, "${fileName}.xlsx")
            tr4AfcElaborazioneService.createLogFile(context, "${fileName}.xlsx", xlsx, tr4AfcElaborazioneService.tipoLog.XLSX)
        } catch (Exception e) {
            afcElaborazioneService.addLogPerContext(context, e.message)

            e.printStackTrace()
        }

    }
}
