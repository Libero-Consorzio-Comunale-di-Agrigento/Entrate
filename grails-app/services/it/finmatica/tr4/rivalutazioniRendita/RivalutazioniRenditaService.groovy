package it.finmatica.tr4.rivalutazioniRendita

import grails.transaction.Transactional
import it.finmatica.tr4.RivalutazioneRendita
import it.finmatica.tr4.dto.RivalutazioneRenditaDTO

@Transactional
class RivalutazioniRenditaService {

    /**
     * Necessariamente i paramentri non devono essere null
     * @assert null != criteria.tipoTributo
     */
    Collection<RivalutazioneRenditaDTO> getByCriteria(def criteria = [:]) {

        def parametri = [
                p_tipoTributo: criteria.tipoTributo as String,
        ]

        def condition = """rr.tipoOggetto.tipoOggetto = ogtr.tipoOggetto.tipoOggetto AND ogtr.tipoTributo.tipoTributo = :p_tipoTributo"""

        if (criteria?.anno) {
            parametri << ['p_anno': (Short) criteria.anno]
            condition += """ AND rr.anno = :p_anno"""
        }

        if (criteria?.tipoOggetto) {
            parametri << ['p_tipoOggetto': (Long) criteria.tipoOggetto]
            condition += """ AND rr.tipoOggetto.tipoOggetto = :p_tipoOggetto"""
        }

        if (criteria?.aliquota) {
            parametri << ['p_aliquota': (BigDecimal) criteria.aliquota]
            condition += """ AND rr.aliquota = :p_aliquota"""
        }

        //-- filtering criteria | criteria.tipoOggetto escluso perchè gia presente
        if (criteria?.da) {
            parametri << ['p_DaAnno': (Short) criteria.da]
            condition += """ AND rr.anno >= :p_DaAnno"""
        }

        if (criteria?.a) {
            parametri << ['p_AAnno': (Short) criteria.a]
            condition += """ AND rr.anno <= :p_AAnno"""
        }

        if (criteria?.daAliquota) {
            parametri << ['p_daAliquota': (BigDecimal) criteria.daAliquota]
            condition += """ AND rr.aliquota >= :p_daAliquota"""
        }
        if (criteria?.aAliquota) {
            parametri << ['p_aAliquota': (BigDecimal) criteria.aAliquota]
            condition += """ AND rr.aliquota <= :p_aAliquota"""
        }

        return doExecute(condition, parametri)
    }

    def salva(RivalutazioneRenditaDTO dto) {
        return dto.toDomain().save(flush: true, failOnError: true)
    }

    void elimina(RivalutazioneRenditaDTO dto) {
        dto.toDomain().delete(failOnError: true)
    }

    boolean exist(def criteria = [:]) {
        Collection<RivalutazioneRenditaDTO> result = getByCriteria(criteria)

        return getByCriteria(criteria).size() > 0
    }


    private static Collection<RivalutazioneRenditaDTO> doExecute(def condition, def parametri) {

        // Uso l'alias di classe per essere sicuro che i dati recuperati vengano correttamente castati.
        def fields = """rr"""
        def from = """RivalutazioneRendita rr, OggettoTributo ogtr"""
        def order = """rr.anno desc, rr.tipoOggetto.tipoOggetto"""

        def query = """SELECT ${fields}
                                FROM ${from}
                                WHERE ${condition}
                                ORDER BY ${order}"""

        def result = RivalutazioneRendita.executeQuery(query, parametri)

        // richiede il fetch
        return result.toDTO(["tipoOggetto", "tipoOggetto.oggettiTributo.tipoTributo", "tipoOggetto.rivalutazioniRendita"])
    }

}
