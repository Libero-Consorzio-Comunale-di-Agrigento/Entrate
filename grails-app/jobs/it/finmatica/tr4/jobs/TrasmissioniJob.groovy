package it.finmatica.tr4.jobs

import it.finmatica.afc.jobs.AfcElaborazioneService
import it.finmatica.tr4.Trasmissione
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.trasmissioni.TrasmissioniService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

class TrasmissioniJob {

    private static Log log = LogFactory.getLog(TrasmissioniJob)

    AfcElaborazioneService afcElaborazioneService
    TrasmissioniService trasmissioniService
    CommonService commonService

    static triggers = {
    }

    def group = "TrasmissioniGroup"

    def description = "Caricamento Trasmissioni"

    def concurrent = false

    def execute(context) {

        log.info "Inizio Job [$description]"

        def folderPath = trasmissioniService.parametroFtpFolder
        def fileSeparator = File.separator

        def numFileAnalizzati = 0
        def numFileCaricati = 0
        def numFileNonTrattati = 0

        try {

            def folder = new File(folderPath)
            log.info "Path da analizzare: ${folderPath}"
            log.info "Numero file: ${folder.list().length}"

            folder.list().each { fileName ->

                def filePath = "${folderPath}${fileSeparator}${fileName}"
                def file = new File(filePath)

                log.info "Analizzo file: ${fileName}, Dimensione: ${commonService.humanReadableSize(file.length())}"
                numFileAnalizzati++

                def currentFileHash = trasmissioniService.getHashDaFilePath(filePath)
                def trasmissioneHash = trasmissioniService.getUltimoHashDaNomeFile(fileName)?.hash

                if (trasmissioneHash) { //File già esistente sul db

                    //Se gli hash sono differenti carico il file in FTP_TRASMISSIONI
                    if (currentFileHash != trasmissioneHash) {

                        log.info "L'hash del file corrente e l'hash dell'ultimo file caricato sono differenti"
                        log.info "Inizio caricamento file ${fileName}"

                        Trasmissione newTrasmissione = creaTrasmissione(currentFileHash, fileName, filePath)
                        trasmissioniService.salvaTrasmissione(newTrasmissione)
                        numFileCaricati++

                    } else { //Hash uguali, nessuna operazione da eseguire
                        log.info "L'hash del file corrente e l'hash dell'ultimo file caricato sono uguali, nessuna operazione necessaria"
                        numFileNonTrattati++
                    }

                } else { //File non esistente sul db, viene inserito una nuova trasmissione

                    log.info "Nuova trasmissione"
                    log.info "Inizio caricamento file ${fileName}"

                    Trasmissione newTrasmissione = creaTrasmissione(currentFileHash, fileName, filePath)
                    trasmissioniService.salvaTrasmissione(newTrasmissione)
                    numFileCaricati++
                }
            }

        } catch (Exception e) {

            e.printStackTrace()
            log.info "Errore in [${description}]: " + e.getMessage()
            numFileNonTrattati++

        } finally {

            def messaggio = "File analizzati: ${numFileAnalizzati}\nFile caricati: ${numFileCaricati}\nFile per cui non era necessaria alcuna azione: ${numFileNonTrattati}"
            afcElaborazioneService.addLogPerContext(context, messaggio)
            messaggio.split("\n").each {
                log.info it
            }
            log.info "Completato Job [${description}]"
        }

    }

    private def creaTrasmissione(def fileHash, def fileName, def filePath) {

        Trasmissione trasmissione = new Trasmissione()

        trasmissione.idDocumento = trasmissioniService.getNextNumSequenza()
        trasmissione.utente = "JOB_AUTO"
        trasmissione.direzione = "E"
        trasmissione.hash = fileHash
        trasmissione.dataVariazione = new Date()
        trasmissione.nomeFile = fileName
        trasmissione.clobFile = trasmissioniService.creaClobFile(filePath)

        return trasmissione
    }

}
