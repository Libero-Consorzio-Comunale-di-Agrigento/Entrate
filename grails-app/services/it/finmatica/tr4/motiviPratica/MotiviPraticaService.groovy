package it.finmatica.tr4.motiviPratica

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.MotiviPratica
import it.finmatica.tr4.dto.MotiviPraticaDTO

@Transactional
class MotiviPraticaService {

    def dataSource

    /**
     * @assert criteria.tipoTributo != null
     */
    Collection<MotiviPraticaDTO> getByCriteria(def criteria = [:]) {
        def result = MotiviPratica.createCriteria().list {
            and {
                if (criteria?.daAnno) {
                    gte('anno', (Short) criteria.daAnno)
                }
                if (criteria?.aAnno) {
                    lte('anno', (Short) criteria.aAnno)
                }
                if (criteria?.motivo) {
                    ilike((String) "motivo", (String) criteria.motivo)
                }
                if (criteria?.tipoPratica) {
                    eq('tipoPratica', criteria.tipoPratica)
                }
                or {
                    isNull('tipoTributo')
                    if (criteria?.tipoTributo) {
                        eq('tipoTributo', criteria.tipoTributo)
                    }
                }
            }

            order('tipoPratica', 'asc')
            order('sequenza', 'asc')
        }

        return result.toDTO()

    }

    def salva(MotiviPraticaDTO dto) {

        return dto.toDomain().save(flush: true, failOnError: true)
    }

    void elimina(MotiviPraticaDTO dto) {
        dto.toDomain().delete(failOnError: true)
    }


    def getNextSequenza(def tipoTributo) {

        Short next

        Sql sql = new Sql(dataSource)
        sql.call(
                '{CALL MOTIVI_PRATICA_NR(?,?)}',
                [tipoTributo, Sql.NUMERIC]
        ) {
            next = it
        }

        return next
    }
}
