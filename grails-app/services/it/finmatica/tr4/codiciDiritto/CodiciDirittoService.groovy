package it.finmatica.tr4.codiciDiritto

import it.finmatica.tr4.CodiceDiritto
import it.finmatica.tr4.dto.CodiceDirittoDTO

class CodiciDirittoService {

    static def TIPI_TRATTAMENTO = [
            [eccezione: null, descrizione: 'Normale'],
                                   [eccezione: 'E', descrizione: 'Esenzione'],
            [eccezione: 'N', descrizione: 'Non Trattare']
    ]

    def getListaCodiciDiritto(def filtro) {
        def elenco = CodiceDiritto.createCriteria().list {
            if (filtro.codDiritto) {
                ilike('codDiritto', filtro.codDiritto)
            }
            if (filtro.daOrdinamento) {
                ge('ordinamento', filtro.daOrdinamento as Short)
            }
            if (filtro.aOrdinamento) {
                le('ordinamento', filtro.aOrdinamento as Short)
            }
            if (filtro.descrizione) {
                ilike('descrizione', filtro.descrizione)
            }
            if (filtro.eccezione) {
                if (filtro.eccezione == 'NULL') {
                    isNull('eccezione')
                } else {
                    eq('eccezione', filtro.eccezione)
                }
            }

            order('ordinamento', 'asc')
        }

        def listaCodiciDiritto = []

        elenco.collect({ cd ->
            def codiceDiritto = [:]

            codiceDiritto.dto = cd.toDTO()
            codiceDiritto.codDiritto = cd.codDiritto
            codiceDiritto.ordinamento = cd.ordinamento
            codiceDiritto.descrizione = cd.descrizione
            codiceDiritto.note = cd.note
            codiceDiritto.eccezione = TIPI_TRATTAMENTO.find({ it.eccezione == cd.eccezione }).descrizione

            listaCodiciDiritto << codiceDiritto
        })

        return listaCodiciDiritto
    }

    def salvaCodiceDiritto(CodiceDirittoDTO codiceDiritto) {
        codiceDiritto.toDomain().save(failOnError: true, flush: true)
    }

    def eliminaCodiceDiritto(CodiceDirittoDTO codiceDiritto) {
        codiceDiritto.toDomain().delete(failOnError: true, flush: true)
    }

    def existsCodiceDiritto(CodiceDirittoDTO codiceDiritto) {
        return CodiceDiritto.findByCodDiritto(codiceDiritto.codDiritto) != null
    }
}
