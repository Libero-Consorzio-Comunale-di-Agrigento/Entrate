package it.finmatica.tr4.speseNotifica

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.SpesaNotifica
import it.finmatica.tr4.codifiche.CodificheTipoNotificaService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.dto.SpesaNotificaDTO

@Transactional
class SpeseNotificaService {

    private static BigDecimal MIN_IMPORTO = 0.01

    CodificheTipoNotificaService codificheTipoNotificaService
    CommonService commonService
    def dataSource

    def getListaSpeseNotifica(def filter = [:]) {
        SpesaNotifica.createCriteria().list {
            eq('tipoTributo.tipoTributo', filter.tipoTributo.tipoTributo)
            if (filter.descrizione) {
                ilike('descrizione', filter.descrizione)
            }
            if (filter.descrizioneBreve) {
                ilike('descrizioneBreve', filter.descrizioneBreve)
            }
            if (filter.daImporto) {
                ge('importo', filter.daImporto as BigDecimal)
            }
            if (filter.aImporto) {
                le('importo', filter.aImporto as BigDecimal)
            }
            if (filter.tipoNotifica) {
                eq('tipoNotifica.tipoNotifica', filter.tipoNotifica.tipoNotifica)
            }
        }.toDTO(['tipoNotifica'])
    }

    def creaSpesaNotifica(def tipoTributo) {
        def tipoTributoDTO = OggettiCache.TIPI_TRIBUTO.valore.find { it.tipoTributo == tipoTributo.tipoTributo }
        return new SpesaNotificaDTO(tipoTributo: tipoTributoDTO)
    }

    def clonaSpesaNotifica(SpesaNotificaDTO spesaNotifica) {
        def newSpesaNotifica = commonService.clona(spesaNotifica)
        newSpesaNotifica.sequenza = null
        return newSpesaNotifica
    }

    synchronized def salvaSpesaNotifica(SpesaNotifica spesaNotifica) {
        if (!spesaNotifica.sequenza) {
            spesaNotifica.sequenza = getNextSequenza(spesaNotifica.tipoTributo.tipoTributo) as Short
        }
        spesaNotifica.save(failOnError: true, flush: true)
    }

    def getNextSequenza(def tipoTributo) {
        def sequenza
        Sql sql = new Sql(dataSource)
        sql.call('{call SPESE_NOTIFICA_NR(?, ?)}',
                [tipoTributo, Sql.NUMERIC],
                { sequenza = it })
        if (!sequenza) {
            throw new IllegalStateException('Impossibile ottenere nuova sequenza per Spesa Notifica')
        }
        return sequenza
    }

    def eliminaSpesaNotifica(SpesaNotifica spesaNotifica) {
        spesaNotifica.delete(failOnError: true, flush: true)
    }

    def getListaTipiNotifica() {
        codificheTipoNotificaService.getListaTipiNotifica()
    }

    def getPositiveSpeseNotifica(def tipoTributo) {
        getListaSpeseNotifica([
                tipoTributo: tipoTributo,
                daImporto  : MIN_IMPORTO
        ])
    }
}
