package it.finmatica.tr4.jobs

import it.finmatica.tr4.elaborazioni.AttivitaElaborazione
import it.finmatica.tr4.elaborazioni.AttivitaElaborazioneDocumento
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.elaborazioni.StatoAttivita
import org.apache.commons.io.FileUtils
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

class ElaborazioniInvioATipografiaJob {

    private static Log log = LogFactory.getLog(ElaborazioniInvioATipografiaJob)

    ElaborazioniService elaborazioniService

    static triggers = {}

    def group = "ElaborazioniMassiveGroup"

    def description = "Invio a tipografia"

    def concurrent = false

    def execute(context) {

        def nowElaborazione = System.currentTimeMillis()

        AttivitaElaborazione attivita = AttivitaElaborazione.get(context.mergedJobDataMap.get('attivita'))
        def cliente = context.mergedJobDataMap.get('cliente')
        def tipoLimiteFile = context.mergedJobDataMap.get('tipoLimiteFile')
        def limiteFile = context.mergedJobDataMap.get('limiteFile')

        def dettagli = elaborazioniService.listaDettagliDaElaborare(
                attivita.elaborazione,
                elaborazioniService.dettagliOrderBy
        )

        def fileName = "${attivita.elaborazione.nomeElaborazione.replace("/", "-").replace("\\", "-")}_${attivita.id}".replace(" ", "_").toUpperCase()

        try {

            // Creazione del folder per l'elaborazione
            def outputFolder = "${elaborazioniService.getDocFolder()}${File.separator}${attivita.id}${File.separator}"
            new File(outputFolder).mkdir()
            def logFile = new File("${outputFolder}/log.txt")

            elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_IN_CORSO))

            log.info "Avvio job per attvità ${attivita.id} - ${attivita.tipoAttivita.descrizione} per ${dettagli.size()} documenti."
            logFile << "Avvio job per attvità ${attivita.id} - ${attivita.tipoAttivita.descrizione} per ${dettagli.size()} documenti.\n"

            log.info "Generazione pdf..."
            logFile << "Generazione pdf...\n"
            def mergePdfResult = elaborazioniService.mergePDF(attivita.elaborazione.id, outputFolder, tipoLimiteFile, limiteFile)

            def fileIndex = 1
            mergePdfResult.each { k, v ->
                // Rename del file pdf
                new File(k).renameTo(new File("${outputFolder}${fileName}_${(fileIndex as String).padLeft(2, "0")}.pdf"))
                log.info "Generazione pdf conclusa."
                logFile << "Generazione pdf conclusa.\n\n"

                log.info "Generazione CSV..."
                logFile << "Generazione CSV...\n"
                elaborazioniService.inviaATipografia(v, attivita.id, cliente, fileName, outputFolder, fileIndex)
                log.info "Generazione CSV completata."
                logFile << "Generazione CSV completata.\n"

                fileIndex++
            }

            // Creazione zip
            def zipFileName = "${outputFolder}${fileName}.zip"
            def BUFFER_SIZE = 250 * 1024 * 1024
            def buffer = new byte[BUFFER_SIZE]

            log.info "Salvataggio file ZIP..."
            logFile << "Salvataggio file ZIP...\n"
            ZipOutputStream zipFile = new ZipOutputStream(new FileOutputStream(zipFileName))
            new File(outputFolder).eachFile() { file ->
                // Si eclude il file zip
                if (file.isFile() && !file.name.endsWith(".zip") && file.name != 'log.txt') {
                    zipFile.putNextEntry(new ZipEntry(file.name))
                    file.withInputStream {
                        int len
                        while ((len = it.read(buffer)) > 0) {
                            zipFile.write(buffer, 0, len)
                        }
                        zipFile.closeEntry()
                    }
                }
            }

            zipFile.close()
            log.info "Salvataggio file CSV completato."
            logFile << "Salvataggio file CSV completato.\n"

            // Eliminazione file temporanei
            log.info "Finalizzazione attività..."
            logFile << "Finalizzazione attività...\n"

            FileUtils.listFiles(new File(outputFolder), ["pdf", "csv"] as String[], false).each {
                it.delete()
            }

            // Salvataggio dell'informazione sul documento
            def attDoc = AttivitaElaborazioneDocumento.get(attivita.id)
            attDoc.documento = "URL:${zipFileName}".getBytes("UTF-8")
            attivita.save(failOnError: true, flush: true)
            log.info "Finalizzazione attività completata."
            logFile << "Finalizzazione attività completata."


            log.info "Job per attvità ${attivita.id} - ${attivita.tipoAttivita.descrizione} per ${dettagli.size()} documenti conclusa."
            logFile << "Job per attvità ${attivita.id} - ${attivita.tipoAttivita.descrizione} per ${dettagli.size()} documenti conclusa.\n"

            elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_COMPLETATA))

            def tempoElaborazione = ((System.currentTimeMillis() - nowElaborazione) as BigDecimal) / 1000
            log.info "Attività [${attivita.elaborazione.nomeElaborazione} - ${attivita.id}] eseguita in ${tempoElaborazione}s."
            logFile << "Attività [${attivita.elaborazione.nomeElaborazione} - ${attivita.id}] eseguita in ${tempoElaborazione}s.\n"

        } catch (Exception e) {
            log.error(e)
            elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_ERRORE), e.message)
        }
    }
}
