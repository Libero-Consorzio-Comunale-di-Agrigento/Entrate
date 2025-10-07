package it.finmatica.tr4.speseIstruttoria

import grails.transaction.Transactional
import it.finmatica.tr4.SpeseIstruttoria
import org.hibernate.SessionFactory

@Transactional
class SpeseIstruttoriaService {

    SessionFactory sessionFactory


    def getListaSpeseIstruttoria(def tipoTributo, def filtri) {

        return SpeseIstruttoria.createCriteria().list {

            eq("tipoTributo", tipoTributo)

            if (filtri?.annoDa != null) {
                ge("anno", filtri.annoDa as short)
            }

            if (filtri?.annoA != null) {
                le("anno", filtri.annoA as short)
            }

            if (filtri?.daImportoDa != null) {
                ge("daImporto", filtri.daImportoDa as BigDecimal)
            }

            if (filtri?.daImportoA != null) {
                le("daImporto", filtri.daImportoA as BigDecimal)
            }

            if (filtri?.aImportoDa != null) {
                ge("aImporto", filtri.aImportoDa as BigDecimal)
            }

            if (filtri?.aImportoA != null) {
                le("aImporto", filtri.aImportoA as BigDecimal)
            }

            if (filtri?.daSpese != null) {
                ge("spese", filtri.daSpese as BigDecimal)
            }

            if (filtri?.aSpese != null) {
                le("spese", filtri.aSpese as BigDecimal)
            }

            if (filtri?.daPercInsolvenza != null) {
                ge("percInsolvenza", filtri.daPercInsolvenza as BigDecimal)
            }

            if (filtri?.aPercInsolvenza != null) {
                le("percInsolvenza", filtri.aPercInsolvenza as BigDecimal)
            }

            order("anno", "asc")
            order("daImporto", "asc")
            order("aImporto", "asc")
        }
    }

    def existsSpeseIstruttoria(def tipoTributo, def anno, def importoDa) {

        def lista = SpeseIstruttoria.createCriteria().list {

            eq('tipoTributo', tipoTributo)
            eq("anno", anno as short)
            eq("daImporto", importoDa)
        }

        return lista.size() > 0
    }

    def existsOverlappingSpesaIstruttoria(SpeseIstruttoria spesa) {
        return SpeseIstruttoria.createCriteria().count {

            eq('tipoTributo', spesa.tipoTributo)
            eq("anno", spesa.anno)

            // Avoiding to involve current interesse when editing it
            if (spesa.daImporto != null) {
                ne('daImporto', spesa.daImporto)
            }

            ge('aImporto', spesa.daImporto)
            le('daImporto', spesa.aImporto)
        } > 0
    }

    def salvaSpesaIstruttoria(def spesa) {
        spesa.save(failOnError: true, flush: true)
    }

    def eliminaSpesaIstruttoria(def spesa) {
        spesa.delete(failOnError: true, flush: true)
    }
}
