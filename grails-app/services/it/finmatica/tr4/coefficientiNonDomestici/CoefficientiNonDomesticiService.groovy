package it.finmatica.tr4.coefficientiNonDomestici

import grails.transaction.Transactional
import it.finmatica.tr4.CoefficientiNonDomestici
import it.finmatica.tr4.dto.CoefficientiNonDomesticiDTO

@Transactional
class CoefficientiNonDomesticiService {

    int countByCriteria(def criteria = [:]) {
        return CoefficientiNonDomestici.createCriteria().count {

            eq("anno", criteria.annoTributo as Short)
            eq("tributo", criteria.codiceTributo as Short) // Relativo a CODICI_TRIBUTO.TRIBUTO
        }
    }

    Collection<CoefficientiNonDomesticiDTO> getByCriteria(def criteria = [:], boolean byFilteringCriteria) {
        return byFilteringCriteria ? getByFilteringCriteria(criteria).toDTO() : getByCriteriaInternal(criteria).toDTO()
    }

    boolean exist(def criteria = [:]) {
        return !getByCriteriaInternal(criteria).empty
    }

    private static Collection<CoefficientiNonDomestici> getByCriteriaInternal(def criteria = [:]) {

        return CoefficientiNonDomestici.createCriteria().list {

            if (criteria?.codiceTributo) {
                eq("tributo", criteria.codiceTributo as Short) // Relativo a CODICI_TRIBUTO.TRIBUTO
            }
            if (criteria?.annoTributo) {
                eq("anno", criteria.annoTributo as Short)
            }
            if (criteria?.categoria) {
                eq("categoria", criteria.categoria as Short)
            }

            order("tributo", 'asc')
            order("anno", 'desc')
            order("categoria", 'asc')
        }
    }

    private static Collection<CoefficientiNonDomestici> getByFilteringCriteria(def criteria = [:]) {

        return CoefficientiNonDomestici.createCriteria().list {
            if (criteria?.daCategoria) gte("categoria", criteria.daCategoria as Short)
            if (criteria?.aCategoria) lte("categoria", criteria.aCategoria as Short)

            if (criteria?.daCoefficientePotenziale) gte("coeffPotenziale", criteria.daCoefficientePotenziale as BigDecimal)
            if (criteria?.aCoefficientePotenziale) lte("coeffPotenziale", criteria.aCoefficientePotenziale as BigDecimal)

            if (criteria?.daCoefficienteProduzione) gte("coeffProduzione", criteria.daCoefficienteProduzione as BigDecimal)
            if (criteria?.aCoefficienteProduzione) lte("coeffProduzione", criteria.aCoefficienteProduzione as BigDecimal)

            eq("tributo", criteria.codiceTributo as Short) // Relativo a CODICI_TRIBUTO.TRIBUTO
            eq("anno", criteria.annoTributo as Short)

            order("tributo", 'asc')
            order("anno", 'desc')
            order("categoria", 'asc')
        }
    }

    def salva(CoefficientiNonDomesticiDTO dto) {
        return dto.toDomain().save(flush: true, failOnError: true)
    }

    void elimina(CoefficientiNonDomesticiDTO dto) {
        dto.toDomain().delete(failOnError: true)
    }

    /**
     * Recupera la lista degli anni da cui è possibile copiare i dati.
     */
    def getListaAnniDuplicabiliByCodiceTributo(def codiceTributo) {
        return CoefficientiNonDomestici.createCriteria().list {
            eq("tributo", codiceTributo as Short)
            projections {
                distinct('anno')
                order('anno', 'desc')
            }
        }
    }

}
