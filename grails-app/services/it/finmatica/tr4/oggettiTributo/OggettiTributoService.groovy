package it.finmatica.tr4.oggettiTributo

import grails.transaction.Transactional
import it.finmatica.tr4.OggettoTributo
import it.finmatica.tr4.dto.OggettoTributoDTO

@Transactional
class OggettiTributoService {

    /**
     * @assert criteria != null
     */
    Collection<OggettoTributoDTO> getByCriteria(def criteria = [:]) {
        // viene usato HQL in quanto tramite i criteria non si riesce a fare usa sola chiamata in join
        // I cast sono necessari :
        //      il tipo "Number" viene interpretato da Hibernate come java.lang.Long
        //      mentre da Java vengono interpretati come java.Lang.Integer
        def parametri = [
                pTipoTributo: criteria.tipoTributo as String,
        ]

        def fields = """ogtr """
        def from = """OggettoTributo ogtr
							inner join fetch ogtr.tipoOggetto tiog
							inner join fetch ogtr.tipoTributo titr"""
        def condition = """titr.tipoTributo = :pTipoTributo"""
        def order = """tiog.tipoOggetto"""

        if (criteria.da) {
            parametri << ['p_da_id': (Long) criteria.da]
            condition += """ AND tiog.tipoOggetto >= :p_da_id"""
        }

        if (criteria.a) {
            parametri << ['p_a_id': (Long) criteria.a]
            condition += """ AND tiog.tipoOggetto <= :p_a_id"""
        }

        if (criteria.descrizione) {
            parametri << ['p_descrizione': criteria.descrizione]
            condition += """ AND UPPER(tiog.descrizione) like UPPER(:p_descrizione)"""
        }

        def query = """SELECT ${fields}
                                FROM ${from}
                                WHERE ${condition}
                                ORDER BY ${order}"""

        return OggettoTributo.executeQuery(query, parametri).toDTO()
    }

    Collection<OggettoTributoDTO> getTipiOggettoSenzaOggettiTributoByTipoTributo(def criteria = [:]) {
        // viene usato HQL in quanto tramite i criteria non si riesce a fare usa sola chiamata in join

        def parametri = [
                pTipoTributo: criteria.tipoTributo as String,
        ]

        String query = """
			select ogtr from OggettoTributo ogtr
			inner join fetch ogtr.tipoOggetto tiog
			left outer join fetch ogtr.tipoTributo titr
			where titr.tipoTributo = :pTipoTributo
			and ogtr.tipoTributo is NULL
			order by tiog.tipoOggetto
		"""

        return OggettoTributo.executeQuery(query, parametri).toDTO()
    }

    /**
     * @assert false = dto.toDomain().exists()
     */
    def salva(OggettoTributoDTO dto) {
        return dto.toDomain().save(flush: true, failOnError: true)
    }

    void elimina(OggettoTributoDTO dto) {
        dto.toDomain().delete(failOnError: true)
    }
}
