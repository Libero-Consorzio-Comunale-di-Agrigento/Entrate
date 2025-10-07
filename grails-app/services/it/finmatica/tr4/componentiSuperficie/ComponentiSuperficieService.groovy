package it.finmatica.tr4.componentiSuperficie

import grails.transaction.Transactional
import it.finmatica.tr4.ComponentiSuperficie
import it.finmatica.tr4.dto.ComponentiSuperficieDTO

@Transactional
class ComponentiSuperficieService {

    Collection<ComponentiSuperficieDTO> getByCriteria(def criteria = [:]) {
        return getByCriteria_internal(criteria).toDTO()
    }

    boolean exist(def criteria = [:]) {
        return getByCriteria_internal(criteria).size() > 0
    }

    private static Collection<ComponentiSuperficie> getByCriteria_internal(def criteria = [:]) {

        return ComponentiSuperficie.createCriteria().list {
            if (criteria?.anno) {
                eq("anno", criteria.anno as Short)
            }
            if (criteria?.numeroFamiliari) {
                eq("numeroFamiliari", criteria.numeroFamiliari as Short)
            }
            if (criteria?.daAnno) {
                gte("anno", criteria.daAnno as Short)
            }
            if (criteria?.aAnno) {
                lte("anno", criteria.aAnno as Short)
            }
            if (criteria?.daNumeroFamiliari) {
                gte("numeroFamiliari", criteria.daNumeroFamiliari as Short)
            }
            if (criteria?.aNumeroFamiliari) {
                lte("numeroFamiliari", criteria.aNumeroFamiliari as Short)
            }
            if (criteria?.daDaConsistenza) {
                gte("daConsistenza", criteria.daDaConsistenza as BigDecimal)
            }
            if (criteria?.aDaConsistenza) {
                lte("daConsistenza", criteria.aDaConsistenza as BigDecimal)
            }
            if (criteria?.daaConsistenza) {
                gte("aConsistenza", criteria.daaConsistenza as BigDecimal)
            }
            if (criteria?.aaConsistenza) {
                lte("aConsistenza", criteria.aaConsistenza as BigDecimal)
            }
            order("anno", 'desc')
            order("numeroFamiliari", 'asc')
            order("daConsistenza", 'asc')
            order("aConsistenza", 'asc')
        }
    }

    def salva(ComponentiSuperficieDTO dto) {
        return dto.toDomain().save(flush: true, failOnError: true)
    }

    void elimina(ComponentiSuperficieDTO dto) {
        dto.toDomain().delete(failOnError: true)
    }

}
