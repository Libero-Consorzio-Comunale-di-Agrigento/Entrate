package it.finmatica.datiesterni.beans

import it.finmatica.tr4.datiesterni.DocumentoCaricato
import it.finmatica.tr4.datiesterni.ImportaService

import org.apache.log4j.Logger;

class ImportUtenze {

    private static final Logger log = Logger.getLogger(ImportUtenze.class)

    ImportaService importaService

    def importaUtenze(def parametri) {
        long idDocumento = parametri.idDocumento
        DocumentoCaricato doc = DocumentoCaricato.get(idDocumento)

        InputStream fileCaricato = new ByteArrayInputStream(doc.contenuto)

        def tracciato = []

        def fornitura = null

        def row = 0

        def tipoUtenza = ""

        try {
            fileCaricato.eachLine { line ->

                // Record 0, si determina il tipo di tracciato da usare.
                if (line.startsWith('0')) {
                    switch (determinaTipoUtenza(line)) {
                        case 'E':
                            tipoUtenza = 'elettriche'
                            log.info "Tipo di utenza: ELETTRICA"
                            tracciato = TracciatiUtenze.UTE_ELE_RECORD_2011
                            break
                        case 'G':
                            tipoUtenza = 'gas'
                            log.info "Tipo di utenza: GAS"
                            tracciato = TracciatiUtenze.UTE_GAS_RECORD_2011
                            break
                        default:
                            throw new RuntimeException("Tipo di tracciato non supportato!")
                    }

                    // Elaborazione del record 0
                    fornitura = importaService.creaFornituraUtenze(elaboraRecord(TracciatiUtenze.UTE_RECORD_0, line), parametri)
                } else if (line.startsWith('1')) {
                    // Si elabora il record
                    importaService.creaFornituraUtenze(elaboraRecord(tracciato, line), parametri, fornitura)
                } else if (line.startsWith('9')) {
                    // Record di coda, non viene elaborato.
                }
                row++
            }

            def datiCaricati = importaService.salvaFornituraUtenze(fornitura)

            doc.note = "Caricate $datiCaricati utenze $tipoUtenza."
            doc.stato = 2
            doc.utente = parametri.utente.getDomainObject()
            doc.save(flush: true, failOnError: true)

            return "file " + doc.nomeDocumento + " importato con successo"
        } catch (Throwable e) {
            log.error("""Errore in importazione utenze riga [$row] """ + e.getMessage())
            doc.stato = 4
            doc.utente = parametri.utente.getDomainObject()
            doc.save(flush: true, failOnError: true)
            throw e;
        }
    }

    private def determinaTipoUtenza(def record) {
        if (!record.startsWith('0')) {
            throw new RuntimeException("Tipo record errato!")
        }
        return record.substring(5, 6)
    }

    private def elaboraRecord(def tracciato, def record) {
        def fields = [:]

        def pos = 0
        tracciato.each { k, v ->
            fields[k] = record.substring(pos, pos + v).trim()
            pos += v
        }

        return fields
    }

}
