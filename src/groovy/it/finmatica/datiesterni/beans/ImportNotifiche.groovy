package it.finmatica.datiesterni.beans

import it.finmatica.tr4.datiesterni.DocumentoCaricato
import it.finmatica.tr4.datiesterni.ImportaService
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.pratiche.PraticaTributo
import org.apache.commons.csv.CSVFormat
import org.apache.commons.csv.CSVRecord
import org.apache.log4j.Logger

import java.text.DateFormat
import java.text.SimpleDateFormat

class ImportNotifiche {

    private static final Logger log = Logger.getLogger(ImportNotifiche.class)

    //Indicizzazione di CSVRecord parte da zero
    private def CAMPO_PRATICA = 8 //corrisponde al campo 9
    private def CAMPO_COD_FISCALE = 12 //corrisponde al campo 13
    private def CAMPO_TIPO_NOTIFICA = 16 //corrisponde al campo 17
    private def CAMPO_DATA_NOTIFICA = 23 //corrisponde all'ultimo campo 24

    ElaborazioniService elaborazioniService

    def totaleProcessati
    def totaleAggiornati
    def totaleErrori

    ImportaService importaService

    def logFile(def idDocumento) {
        def folder = "Date_Notifica_per_Pratiche_di_Violazioni"
        def fileSeparator = File.separator

        def logFolder = new File("${elaborazioniService.docFolder}$fileSeparator$folder")
        if (!logFolder.exists()) {
            logFolder.mkdir()
        }

        return new File("${logFolder.absolutePath}$fileSeparator${idDocumento}_log.txt")

    }

    def importaDateNotifiche(def parametri) {

        totaleProcessati = 0
        totaleAggiornati = 0
        totaleErrori = 0

        long idDocumento = parametri.idDocumento
        DocumentoCaricato doc = DocumentoCaricato.get(idDocumento)
        def errorFile = logFile(idDocumento)
        errorFile.write("")

        try {

            log.info "Import date notifiche - Caricamento e lettura file CSV"
            InputStream fileCaricato = new ByteArrayInputStream(doc.contenuto)
            Reader reader = new InputStreamReader(fileCaricato)
            log.info "Import date notifiche - Accesso ad ogni riga"

            Iterable<CSVRecord> records = CSVFormat.DEFAULT.withDelimiter(';' as char).parse(reader)
            for (CSVRecord record : records) {

                totaleProcessati++

                Long pratica
                if (record.get(CAMPO_PRATICA) && record.get(CAMPO_PRATICA) != "") {
                    pratica = Long.valueOf(record.get(CAMPO_PRATICA))

                    if (PraticaTributo.find {
                        and {
                            eq("id", pratica)
                            eq("contribuente.codFiscale", record.get(CAMPO_COD_FISCALE))
                            'in'('tipoPratica', ['A', 'L', 'G', 'I'])
                        }
                    } == null) {
                        totaleErrori++
                        errorFile.append("Pratica: $pratica - Data Notifica: ${record.get(CAMPO_DATA_NOTIFICA)} - Errore: La pratica non esiste\r\n")
                        pratica = null
                    }
                }

                Date dataNotifica

                if (record.get(CAMPO_DATA_NOTIFICA) && record.get(CAMPO_DATA_NOTIFICA) != "") {
                    DateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
                    sdf.lenient = false
                    try {
                        dataNotifica = sdf.parse(record.get(CAMPO_DATA_NOTIFICA))
                    } catch (Exception e) {
                        totaleErrori++
                        errorFile.append("Pratica: $pratica - Data Notifica: ${record.get(CAMPO_DATA_NOTIFICA)} - Errore: $e.message\r\n")
                        log.error(e)
                    }
                }

                def esito = ""
                if (pratica && dataNotifica) {
                    log.info "Pratica: $pratica - Data Notifica: $dataNotifica"
                    esito = importaService.importaDateNotifica(pratica, dataNotifica)
                    if (esito.empty) {
                        totaleAggiornati++
                        log.info "Inserita la data di notifica per corrispondenza di pratica"
                    } else {
                        totaleErrori++
                        errorFile.append("Pratica: $pratica - Data Notifica: ${dataNotifica?.format("dd/MM/yyyy")} - Errore: $esito\r\n")
                    }
                }

                Integer tipoNotifica = null

                // Tipo Notifica
                if (record.get(CAMPO_TIPO_NOTIFICA) && record.get(CAMPO_TIPO_NOTIFICA) != "") {
                    tipoNotifica = Integer.parseInt(record.get(CAMPO_TIPO_NOTIFICA))
                }

                esito = ""
                if (pratica && tipoNotifica) {
                    log.info "Pratica: $pratica - Tipo Notifica: $tipoNotifica"
                    esito = importaService.importaTipiNotifica(pratica, tipoNotifica)
                    if (esito.empty) {
                        log.info "Inserita la tipo notifica per corrispondenza di pratica"
                    } else {
                        totaleErrori++
                        errorFile.append("Pratica: $pratica - Tipo Notifica: ${tipoNotifica} - Errore: $esito\r\n")
                    }
                }

            }

            doc.stato = 2
            doc.utente = parametri.utente.getDomainObject()
            doc.note = "Provvedimenti totali processati: ${totaleProcessati}\n" +
                    "Provvedimenti aggiornati con la data di notifica: ${totaleAggiornati}\n" +
                    "Errori: $totaleErrori"
            doc.save(flush: true, failOnError: true)
            reader.close()

            def esito = "file " + doc.nomeDocumento + " importato con successo\n"
            esito += doc.note
            return esito
        } catch (Throwable e) {
            log.error("Errore in importazione date notifiche " + e.getMessage())
            doc.stato = 4
            doc.utente = parametri.utente.getDomainObject()
            doc.save(flush: true, failOnError: true)
            throw e
        }
    }

}
