package it.finmatica.tr4.jobs

import grails.transaction.Transactional
import it.finmatica.afc.jobs.AfcAllegatoElaborazione
import it.finmatica.afc.jobs.AfcElaborazione
import it.finmatica.afc.jobs.utility.AfcJobUtils
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import org.quartz.JobExecutionContext

@Transactional
class Tr4AfcElaborazioneService {

    def tipoLog = [
            ELABORAZIONI: 'Elaborazioni',
            DATI_ESTERNI: 'DatiEsterni',
            XLSX: 'ExportXLSX'

    ]

    private static final String LOG_FORMAT = "log"
    private String ALLEGATO_NOME_RADICE = 'DatabaseCall: '
    private String ALLEGATO_TIPO = 'DATABASE_CALL_LOG'
    private String ENCLOSING_CHAR_START = "("
    private String ENCLOSING_CHAR_END = ")"
    private String PARAMETERS_SEPARATOR = ","

    ElaborazioniService elaborazioniService

    boolean existsLogFile(AfcElaborazione elaborazione) {
        return existsLogFile(elaborazione.codice)
    }

    def existsLogFile(String codiceElaborazione) {
        return getLogFile(codiceElaborazione) != null
    }

    def getLogFile(AfcElaborazione elaborazione) {
        return getLogFile(elaborazione.codice)
    }

    def getLogFile(String codiceElaborazione) {

        def logFile = null

        for (def folder in tipoLog) {
            String rootFolder = elaborazioniService.docFolder
            File logFolder = new File("$rootFolder${File.separator}${folder.value}")

            if (!logFolder?.exists()) {
                log.info("Non esiste la cartella ${logFolder.absolutePath}")
            }

            FilenameFilter filter = new FilenameFilter() {
                @Override
                boolean accept(File dir, String name) {
                    return name.startsWith(codiceElaborazione)
                }
            }

            List<File> files = logFolder?.listFiles(filter)?.toList()

            if (!files || files.isEmpty()) {
                log.info("Non esiste il file per l'elaborazione ${codiceElaborazione}")
            }

            logFile = files?.empty ? null : files?.first()

            if (logFile) {
                return logFile
            }
        }

        return logFile

    }

    def createLogFile(JobExecutionContext context, String prettyFileName, byte[] fileContent, def tipoLog) {
        File logFile = createLogFile(context, prettyFileName, tipoLog)
        logFile.append(fileContent)
        return logFile
    }

    def createLogFile(JobExecutionContext context, String prettyFileName, def tipoLog) {
        String codiceElaborazione = AfcJobUtils.getCodiceElaborazioneFromContext(context)
        String rootFolder = elaborazioniService.docFolder
        File logFolder = new File("$rootFolder${File.separator}$tipoLog")
        if (!logFolder.exists()) {
            logFolder.mkdir()
        }

        def fileName = "${logFolder.absolutePath}${File.separator}$codiceElaborazione$prettyFileName"

        return new File(fileName)
    }

    def getPrettyFileName(AfcElaborazione elaborazione, File logFile) {
        String fileName = logFile.name
        String name = fileName.substring(0, logFile.name.lastIndexOf("."))
        String extension = fileName.substring(logFile.name.lastIndexOf(".") + 1)

        if (extension == LOG_FORMAT) {
            return "${name}_log.$extension"
        }

        String codiceElaborazione = elaborazione.codice
        return fileName.replace(codiceElaborazione, "")
    }

    def saveDatabaseCall(String codiceElaborazione, String statement) {
        saveDatabaseCall(codiceElaborazione, statement, [])
    }

    def saveDatabaseCall(String codiceElaborazione, String statement, List parametersValues) {
        AfcAllegatoElaborazione allegato = new AfcAllegatoElaborazione()

        allegato.nome = "$ALLEGATO_NOME_RADICE$codiceElaborazione"
        allegato.tipo = ALLEGATO_TIPO
        allegato.testo = getText(statement, parametersValues)
        allegato.elaborazione = AfcElaborazione.findByCodice(codiceElaborazione)

        allegato.save(failOnError: true, flush: true)
    }

    private def getText(String statement, List parametersValues) {
        def text = "Statement: $statement\n${getParametersText(parametersValues)}"
        text.getBytes()
    }

    private def getParametersText(List parametersValues) {
        def parametersText = ""
        if (!parametersValues.isEmpty()) {
            parametersText = "Parameters: $ENCLOSING_CHAR_START\n"
            parametersValues.each { value ->
                parametersText += "${value.toString()}$PARAMETERS_SEPARATOR\n"
            }
            parametersText += ENCLOSING_CHAR_END
        }
        return parametersText
    }

}
