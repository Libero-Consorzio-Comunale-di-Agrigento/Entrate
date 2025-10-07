package it.finmatica.datiesterni.beans

import groovy.json.JsonSlurper
import it.finmatica.tr4.commons.OggettiCache

class TracciatiLocazioni {

    def static determinaTracciato(Long titoloDocumento, String record0) {

        def dataTracciato = Date.parse('yyyy-MM-dd', (record0 =~ /\d{4}-\d{2}-\d{2}/)[0])

        def tipoTracciato = OggettiCache.LOCAZIONI_TIPI_TRACCIATO.valore.find {
            it.titoloDocumento == titoloDocumento && it.dataInizio <= dataTracciato && dataTracciato <= it.dataFine
        }

        def jsonSlurper = new JsonSlurper()
        return jsonSlurper.parseText(tipoTracciato.tracciato)

    }

    def static estraiAnno(String record0) {
        assert record0 && !record0.isEmpty() && record0.startsWith("0"): "Record 0 non valido"

        int annoPos = record0.indexOf("ANNO ") + 5 // Posizione + 4 (caratteri anno) + 1 (spazio)
        if (annoPos > -1) {
            return record0.substring(annoPos, annoPos + 4)
        } else {
            return null
        }
    }
}