package it.finmatica.tr4.contenitori

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.Contenitore
import it.finmatica.tr4.dto.ContenitoreDTO

@Transactional
class ContenitoriService {

    CommonService commonService
    def dataSource

    def getListaContenitori(def filter = [:]) {

        Contenitore.createCriteria().list {
            if (filter.daCodice != null) {
                ge('id', filter.daCodice as Long)
            }
            if (filter.aCodice != null) {
                le('id', filter.aCodice as Long)
            }
            if (filter.descrizione) {
                ilike('descrizione', filter.descrizione)
            }
            if (filter.unitaDiMisura) {
                ilike('unitaDiMisura', filter.unitaDiMisura)
            }
            if (filter.daCapienza != null) {
                ge('capienza', filter.daCapienza as BigDecimal)
            }
            if (filter.aCapienza != null) {
                le('capienza', filter.aCapienza as BigDecimal)
            }

            order('id', 'asc')
        }.toDTO()
    }

    def creaContenitore() {
        return new ContenitoreDTO()
    }

    def clonaContenitore(ContenitoreDTO contenitore) {
        def newContenitore = commonService.clona(contenitore)
        newContenitore.id = null
        return newContenitore
    }

    synchronized def salvaContenitore(Contenitore contenitore) {
        contenitore.save(failOnError: true, flush: true)
    }

    def eliminaContenitore(Contenitore contenitore) {
        contenitore.delete(failOnError: true, flush: true)
    }
}
