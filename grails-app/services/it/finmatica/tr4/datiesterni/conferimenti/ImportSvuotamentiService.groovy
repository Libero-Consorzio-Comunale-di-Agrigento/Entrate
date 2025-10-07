package it.finmatica.tr4.datiesterni.conferimenti


import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.CodiceRfid
import it.finmatica.tr4.Svuotamento
import it.finmatica.tr4.datiesterni.DocumentoCaricato
import org.codehaus.groovy.grails.plugins.DomainClassGrailsPlugin

import java.text.SimpleDateFormat

@Transactional
class ImportSvuotamentiService {

    def dataSource
    def sessionFactory
    def propertyInstanceMap = DomainClassGrailsPlugin.PROPERTY_INSTANCE_MAP

    def importa(def parametri) {

        def idDocumento = parametri.idDocumento
        DocumentoCaricato doc = DocumentoCaricato.get(idDocumento)

        def index = 0
        def okRows = 0
        def koRows = 0

        try {

            if (!doc?.contenuto || doc.contenuto.size() == 0) {
                throw new RuntimeException("Nessun dato da caricare")
            }

            def csvContent = new String(doc.contenuto)

            def rows = csvContent.split("\n")
            if (rows.size() < 2) {
                throw new RuntimeException("Nessun dato da caricare")
            }

            // La prima riga è l'header
            def header = rows[0].split("\\|").collect {
                it
                        .replace("\n", "")
                        .replace("\r", "")
            }

            def svuotamentiNoRfid = ["RFID non caricati"]
            def svuotamentiDataErrata = ["Date incoerenti"]
            def svuotamentiDuplicati = ["Svuotamenti duplicati"]
            def chiaviProcessate = [].toSet()

            // Le righe successive contengono i dati
            rows[1..-1].each { row ->

                try {

                    row = row
                            .replace("\n", "")
                            .replace("\r", "")
                    def values = row.split("\\|", -1) // Usa il flag -1 per mantenere i campi vuoti
                    def dataMap = [header, values].transpose().collectEntries { [(it[0]): it[1]] }

                    def key = generaChiaveRfidData(dataMap)

                    if (chiaviProcessate.contains(key)) {
                        svuotamentiDuplicati << row
                        koRows++
                        return
                    } else {
                        chiaviProcessate += key
                    }

                    // Creare un'istanza di Svuotamento
                    def svuotamento = new Svuotamento()

                    svuotamento.documentoId = idDocumento
                    svuotamento.codRfid = dataMap['cod_sismal']

                    def rfid = CodiceRfid.findByCodRfid(svuotamento.codRfid)

                    // Verifica presenza codice RFID
                    if (!rfid) {
                        svuotamentiNoRfid << row
                        koRows++
                        return
                    }

                    // Verifica correttezza data
                    def dataSvuotamento = convertToDate("${dataMap['data_operazione']} ${dataMap['ora_operazione']}")
                    if (!dataSvuotamento) {
                        svuotamentiDataErrata << row
                    }

                    svuotamento.contribuente = rfid.contribuente
                    svuotamento.oggetto = rfid.oggetto

                    svuotamento.sequenza = getNextSequenza(svuotamento.contribuente.codFiscale, svuotamento.oggetto.id, svuotamento.codRfid)
                    svuotamento.dataSvuotamento = dataSvuotamento
                    svuotamento.gps = dataMap['gps']
                    svuotamento.stato = dataMap['stato']
                    svuotamento.longitudine = dataMap['longitudine'] ? new BigDecimal(dataMap['longitudine'].replace(",", ".")) : null
                    svuotamento.latitudine = dataMap['latitudine'] ? new BigDecimal(dataMap['latitudine'].replace(",", ".")) : null

                    svuotamento.quantita = dataMap['qta']?.trim() ? dataMap['qta'] as Integer : null
                    svuotamento.note = dataMap['note']
                    svuotamento.utente = parametri.utente.id

                    svuotamento.save(flush: true, failOnError: true)

                    okRows++

                    if (++index % 100 == 0) {
                        cleanUpGorm()
                    }
                } catch (Exception e) {
                    koRows++
                    log.error(e.message)
                }
            }

            doc.stato = 2
            doc.note = """${(rows[1..-1]).size()} righe elaborate.
${okRows} righe importate.
${koRows} righe non importate.
"""

            doc.save(flush: true, failOnError: true)

            return """${doc.note}
<FINE_RIEPILOGO>    
       
${svuotamentiNoRfid.empty ? '' : svuotamentiNoRfid.join("\n")}

${svuotamentiDuplicati.empty ? '' : svuotamentiDuplicati.join("\n")}

${svuotamentiDataErrata.empty ? '' : svuotamentiDataErrata.join("\n")}
"""

        } catch (Throwable e) {
            log.error("Errore in importazione svuotamenti " + e.getMessage())
            doc.stato = 4
            doc.utente = parametri.utente.getDomainObject()
            doc.save(flush: true, failOnError: true)
            throw e
        }

    }

    private def isValidDate(String dateString) {
        def dateFormat = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss")
        dateFormat.setLenient(false) // Disabilita l'interpretazione flessibile delle date
        try {
            dateFormat.parse(dateString)
            return true
        } catch (Exception e) {
            return false
        }
    }

    private def convertToDate(String dateString) {
        if (isValidDate(dateString)) {
            def dateFormat = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss")
            return dateFormat.parse(dateString)
        } else {
            return null
        }
    }

    private def cleanUpGorm() {
        def session = sessionFactory.currentSession
        session.flush()
        session.clear()
        propertyInstanceMap.get().clear()
    }

    private def getNextSequenza(def codFiscale, def oggetto, def codRfid) {

        Short newSequenza = 1

        Sql sql = new Sql(dataSource)
        sql.call('{call svuotamenti_nr(?, ?, ?, ?)}',
                [
                        codFiscale,
                        oggetto,
                        codRfid,
                        Sql.NUMERIC
                ],
                { newSequenza = it }
        )

        return newSequenza
    }

    private String generaChiaveRfidData(def row) {
        return "${row['cod_sismal']}:${row['data_operazione']}"
    }
}
