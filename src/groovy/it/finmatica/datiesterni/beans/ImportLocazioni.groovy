package it.finmatica.datiesterni.beans

import it.finmatica.tr4.datiesterni.DocumentoCaricato
import it.finmatica.tr4.datiesterni.ImportaService
import org.apache.log4j.Logger

class ImportLocazioni {

    private static final Logger log = Logger.getLogger(ImportLocazioni.class)

    def totaleRecord = [:]

    ImportaService importaService

    def importaLocazioni(def parametri) {

        totaleRecord = [:]
        long idDocumento = parametri.idDocumento
        DocumentoCaricato doc = DocumentoCaricato.get(idDocumento)

        try {

            def tracciato = []
            def recordFields = []

            InputStream fileCaricato = new ByteArrayInputStream(doc.contenuto)

            fileCaricato.eachLine { line ->
                if (line.charAt(0).toString() == "0") {
                    tracciato = TracciatiLocazioni.determinaTracciato(doc.titoloDocumento.id, line)
                }

                recordFields << elaboraRecord(tracciato, line)

            }

            importaService.creaLocazioni(recordFields, parametri)

            doc.stato = 2
            doc.utente = parametri.utente.getDomainObject()
            doc.note ="Record A dati contratto inseriti: ${totaleRecord['A'] ?: 0}\n" +
                      "Record B dati anagrafici locatore e locatario inseriti: ${totaleRecord['B'] ?: 0}\n" +
                      "Record I dati immobili inseriti: ${totaleRecord['I'] ?: 0}"

            doc.save(flush: true, failOnError: true)

            return "file " + doc.nomeDocumento + " importato con successo"
        } catch (Throwable e) {
            log.error("Errore in importazione locazioni " + e.getMessage())
            doc.stato = 4
            doc.utente = parametri.utente.getDomainObject()
            doc.save(flush: true, failOnError: true)
            throw e
        }
    }

    private def elaboraRecord(def tracciato, def record) {
        def fields = [:]

        def tipoRecord = tracciato[record.substring(0, 1)]
        contaRecord(record.substring(0, 1))
        if (tracciato) {
            tipoRecord.each { k, v ->
                fields[k] = record.substring(v.da, v.a).trim()

            }

            if (tipoRecord == '0') {
                fields['anno'] = TracciatiLocazioni.estraiAnno(record)
            }

        }

        return fields
    }

    private void contaRecord(def tipoRecord) {
        totaleRecord[tipoRecord] = totaleRecord[tipoRecord] ?: 0

        totaleRecord[tipoRecord] += 1
    }
}
