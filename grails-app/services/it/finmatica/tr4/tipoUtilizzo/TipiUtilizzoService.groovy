package it.finmatica.tr4.tipoUtilizzo

import grails.transaction.Transactional
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.TipoUtilizzo
import it.finmatica.tr4.UtilizzoTributo
import org.hibernate.SessionFactory
import transform.AliasToEntityCamelCaseMapResultTransformer

@Transactional
class TipiUtilizzoService {

    SessionFactory sessionFactory

    def tipoTributo
    def tipoUtilizzo

    def deleteUtilizzoTributo(def filter) {
        UtilizzoTributo utilizzoTributo = UtilizzoTributo.createCriteria().get {
            eq('tipoTributo.tipoTributo', filter.tipoTributo)
            eq('tipoUtilizzo.id', filter.tipoUtilizzo)
        }
        utilizzoTributo.delete(failOnError: true, flush: true)
    }

    def salvaUtilizzoTributo(UtilizzoTributo utilizzoTributo) {
        utilizzoTributo.save(failOnError: true, flush: true)
    }

    def getUtilizzoTributo(def tipoTributo) {
        UtilizzoTributo.createCriteria().list() {
            eq('tipoTributo', TipoTributo.findByTipoTributo(tipoTributo))
        }
    }

    def getListaUtilizzoTributo(def filtri = [:]) {
        def parametri = [:]
        parametri << ['p_tipo_trib': filtri.tipoTributo]

        def fields = """TIPI_UTILIZZO.TIPO_UTILIZZO """

        def from = """UTILIZZI_TRIBUTO
                            INNER JOIN TIPI_UTILIZZO ON TIPI_UTILIZZO.TIPO_UTILIZZO=UTILIZZI_TRIBUTO.TIPO_UTILIZZO"""

        def condition = """1=1"""

        if (filtri.tipoTributo) {
            condition += """ AND UTILIZZI_TRIBUTO.TIPO_TRIBUTO = :p_tipo_trib"""
        }

        if (filtri.daId) {
            parametri << ['p_da_id': filtri.daId]
            condition += """ AND TIPI_UTILIZZO.TIPO_UTILIZZO >= :p_da_id"""
        }

        if (filtri.aId) {
            parametri << ['p_a_id': filtri.aId]
            condition += """ AND TIPI_UTILIZZO.TIPO_UTILIZZO <= :p_a_id"""
        }

        if (filtri.descrizione) {
            parametri << ['p_descrizione': filtri.descrizione]
            condition += """ AND UPPER(TIPI_UTILIZZO.DESCRIZIONE) like UPPER(:p_descrizione)"""
        }

        def order = """ UTILIZZI_TRIBUTO.TIPO_TRIBUTO ASC"""

        def query = """SELECT ${fields}
                                FROM ${from}
                                WHERE ${condition}
                                ORDER BY ${order}"""


        def result = sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        TipoUtilizzo.findAllByIdInList(result*.tipoUtilizzo.collect { it as Long }).each { tu ->
            result.findAll { u -> u.tipoUtilizzo == tu.id }.each { r ->
                r.tipoUtilizzo = tu
            }
        }
        result.sort {
            it.tipoUtilizzo.id
        }

        return result
    }

    def getListaUtilizzoTributoCombo(def tipoTributo) {

        def parametri = [:]
        parametri << ['tipoTributo': tipoTributo.tipoTributo]
        def query = """
                select tiut.tipo_utilizzo , tiut.descrizione
                from tipi_utilizzo tiut
                where tiut.tipo_utilizzo not in
               (select uttr.tipo_utilizzo
                  from utilizzi_tributo uttr
                 where uttr.tipo_tributo = :tipoTributo)
                 order by 1
             """

        return sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }
    }
}
