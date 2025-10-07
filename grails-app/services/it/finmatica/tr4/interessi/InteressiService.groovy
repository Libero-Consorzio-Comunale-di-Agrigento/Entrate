package it.finmatica.tr4.interessi

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.Interessi
import it.finmatica.tr4.TipoTributo
import org.hibernate.SessionFactory
import transform.AliasToEntityCamelCaseMapResultTransformer

@Transactional
class InteressiService {

    SessionFactory sessionFactory
    def dataSource

    def getListaInteressi(def filtri) {

        def parametri = [
                pTipoTributo  : filtri.tipoTributo,
                pDaDataInizio : filtri.daDataInizio ?: new Date(0),
                pADataInizio  : filtri.aDataInizio ?: new Date(253402214400000), // 31/12/9999
                pDaDataFine   : filtri.daDataFine ?: new Date(0),
                pADataFine    : filtri.aDataFine ?: new Date(253402214400000),  // 31/12/9999
                pDaAliquota   : filtri.daAliquota ?: 0,
                pAAliquota    : filtri.aAliquota ?: 999999.9999,
                pTipoInteresse: filtri.tipoInteresse,
        ]

        if (filtri.anno) {
            parametri.anno = filtri.anno
        }

        def query = """
                            SELECT INTERESSI.TIPO_TRIBUTO,
                                   INTERESSI.SEQUENZA,
                                   INTERESSI.DATA_INIZIO,
                                   INTERESSI.DATA_FINE,
                                   INTERESSI.ALIQUOTA,
                                   INTERESSI.TIPO_INTERESSE
                            FROM INTERESSI
                            WHERE INTERESSI.TIPO_TRIBUTO = :pTipoTributo AND
                            INTERESSI.DATA_INIZIO >= :pDaDataInizio AND
                            INTERESSI.DATA_INIZIO <= :pADataInizio AND
                            INTERESSI.DATA_FINE >= :pDaDataFine AND
                            INTERESSI.DATA_FINE <= :pADataFine AND
                            INTERESSI.ALIQUOTA >= :pDaAliquota AND
                            INTERESSI.ALIQUOTA <= :pAAliquota AND
                            (:pTipoInteresse IS NULL OR INTERESSI.TIPO_INTERESSE = :pTipoInteresse)
                            ${parametri.anno ? 'AND extract(YEAR from INTERESSI.DATA_INIZIO) <= :anno AND extract(YEAR from INTERESSI.DATA_FINE) >= :anno' : ''}
                            
                            ORDER BY INTERESSI.TIPO_TRIBUTO   ASC,
                                     INTERESSI.TIPO_INTERESSE ASC,
                                     INTERESSI.DATA_INIZIO    ASC,
                                     INTERESSI.DATA_FINE      ASC,
                                     INTERESSI.SEQUENZA       ASC

                           """

        return sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }
    }

    def presenzaSovrapposizioni(Interessi interesse) {
        return Interessi.createCriteria().count {

            if (interesse.sequenza) {
                ne('sequenza', interesse.sequenza)
            }

            eq('tipoTributo', interesse.tipoTributo)
            eq('tipoInteresse', interesse.tipoInteresse)

            ge('dataFine', interesse.dataInizio)
            le('dataInizio', interesse.dataFine)
        } > 0
    }

    def salvaInteresse(Interessi interesse) {
        if (!interesse.sequenza) {
            interesse.sequenza = getNextSequenza(interesse.tipoTributo)
        }
        interesse.save(failOnError: true, flush: true)
    }

    def eliminaInteresse(Interessi interesse) {
        interesse.delete(failOnError: true, flush: true)
    }

    def getInteresse(def tipoTributo, def sequenza) {
        return Interessi.createCriteria().get {
            eq('tipoTributo', tipoTributo)
            eq('sequenza', sequenza as short)
        }
    }

    def getListaTipiTributo() {
        return TipoTributo.list()
    }

    def getNextSequenza(def tipoTributo) {

        Short newSequenza = 1

        Sql sql = new Sql(dataSource)
        sql.call('{call INTERESSI_NR(?, ?)}',
                [
                        tipoTributo,
                        Sql.NUMERIC
                ],
                { newSequenza = it }
        )

        return newSequenza
    }


}
