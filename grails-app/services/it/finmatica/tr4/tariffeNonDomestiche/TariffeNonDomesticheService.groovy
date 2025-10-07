package it.finmatica.tr4.tariffeNonDomestiche

import it.finmatica.tr4.TariffaNonDomestica
import it.finmatica.tr4.dto.TariffaNonDomesticaDTO

class TariffeNonDomesticheService {

    int countByCriteria(def criteria = [:]) {
        return TariffaNonDomestica.createCriteria().count {

            eq("anno", criteria.annoTributo as Short)
            eq("tributo", criteria.codiceTributo as Short) // Relativo a CODICI_TRIBUTO.TRIBUTO
        }
    }

    Collection<TariffaNonDomesticaDTO> getByCriteria(def criteria = [:], boolean byFilteringCriteria) {
        Collection<TariffaNonDomestica> result = byFilteringCriteria ? getByFilteringCriteria(criteria) : getByCriteria_internal(criteria)
        return result.toDTO()
    }

    boolean exist(def criteria = [:]) {
        return getByCriteria_internal(criteria).size() > 0
    }

    private static Collection<TariffaNonDomestica> getByCriteria_internal(def criteria = [:]) {

        return TariffaNonDomestica.createCriteria().list {

            if (criteria?.annoTributo) {
                eq("anno", criteria.annoTributo as Short)
            }
            if (criteria?.codiceTributo) {
                eq("tributo", criteria.codiceTributo as Short)
            }
            if (criteria?.categoria) eq("categoria", criteria.categoria as Short)

            order("tributo", "asc")
            order('anno', 'desc')
            order("categoria", "asc")
        }
    }

    private static Collection<TariffaNonDomestica> getByFilteringCriteria(def criteria = [:]) {

        return TariffaNonDomestica.createCriteria().list {
            if (criteria?.daCategoria != null) gte("categoria", criteria.daCategoria as Short)
            if (criteria?.aCategoria != null) lte("categoria", criteria.aCategoria as Short)

            if (criteria?.daTariffaQuotaFissa != null) gte("tariffaQuotaFissa", criteria.daTariffaQuotaFissa as BigDecimal)
            if (criteria?.aTariffaQuotaFissa != null) lte("tariffaQuotaFissa", criteria.aTariffaQuotaFissa as BigDecimal)

            if (criteria?.daTariffaQuotaVariabile != null) gte("tariffaQuotaVariabile", criteria.daTariffaQuotaVariabile as BigDecimal)
            if (criteria?.aTariffaQuotaVariabile != null) lte("tariffaQuotaVariabile", criteria.aTariffaQuotaVariabile as BigDecimal)

            if (criteria?.daImportoMinimi != null) gte("importoMinimi", criteria.daImportoMinimi as BigDecimal)
            if (criteria?.aImportoMinimi != null) lte("importoMinimi", criteria.aImportoMinimi as BigDecimal)

            if (criteria?.codiceTributo) {
                eq("tributo", criteria.codiceTributo as Short) // Relativo a CODICI_TRIBUTO.TRIBUTO
            }
            if (criteria?.annoTributo) {
                eq("anno", criteria.annoTributo as Short)
            }

            order("tributo", 'asc')
            order('anno', 'desc')
            order("categoria", 'asc')
        }
    }

    def salva(TariffaNonDomesticaDTO dto) {
        return dto.toDomain().save(flush: true, failOnError: true)
    }

    void elimina(TariffaNonDomesticaDTO dto) {
        dto.toDomain().delete(failOnError: true)
    }

    /**
     * Recupera la lista degli anni da cui è possibile copiare i dati.
     */
    def getListaAnniDuplicabiliByCodiceTributo(def codiceTributo) {
        return TariffaNonDomestica.createCriteria().list {
            eq("tributo", codiceTributo as Short)
            projections {
                distinct('anno')
                order('anno', 'desc')
            }
        }
    }
}

