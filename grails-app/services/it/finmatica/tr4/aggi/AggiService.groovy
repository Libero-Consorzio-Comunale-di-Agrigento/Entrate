package it.finmatica.tr4.aggi

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.Aggio
import it.finmatica.tr4.TipoTributo
import org.hibernate.SessionFactory
import transform.AliasToEntityCamelCaseMapResultTransformer

@Transactional
class AggiService {

    SessionFactory sessionFactory
    def dataSource

    def getListaAggi(def filtri) {

//        def parametri = [:]
//
//        parametri << ['p_tipo_trib': tipoTributo]

        def parametri = [
                pTipoTributo        : filtri.tipoTributo,
                pDaDataInizio       : filtri.daDataInizio ?: new Date(0),
                pADataInizio        : filtri.aDataInizio ?: new Date(253402214400000), // 31/12/9999
                pDaDataFine         : filtri.daDataFine ?: new Date(0),
                pADataFine          : filtri.aDataFine ?: new Date(253402214400000), // 31/12/9999
                pDaGiornoInizio     : filtri.daGiornoInizio ?: 0,
                pAGiornoInizio      : filtri.aGiornoInizio ?: 9999,
                pDaGiornoFine       : filtri.daGiornoFine ?: 0,
                pAGiornoFine        : filtri.aGiornoFine ?: 9999,
                pDaAliquota         : filtri.daAliquota ?: 0,
                pAAliquota          : filtri.aAliquota ?: 999999.9999,
                pDaImportoMassimo   : filtri.daImportoMassimo ?: 0,
                pAImportoMassimo    : filtri.aImportoMassimo ?: 999999999999999.99,
                pValidImportoMassimo: filtri.daImportoMassimo || filtri.aImportoMassimo
        ]

        def query = """
                            SELECT aggi.*
                            FROM aggi
                            WHERE aggi.TIPO_TRIBUTO like :pTipoTributo AND
                            aggi.DATA_INIZIO >= :pDaDataInizio AND
                            aggi.DATA_INIZIO <= :pADataInizio AND
                            aggi.DATA_FINE >= :pDaDataFine AND
                            aggi.DATA_FINE <= :pADataFine AND
                            aggi.ALIQUOTA >= :pDaAliquota AND
                            aggi.ALIQUOTA <= :pAAliquota AND
                            aggi.GIORNO_INIZIO >= :pDaGiornoInizio AND
                            aggi.GIORNO_INIZIO <= :pAGiornoInizio AND
                            aggi.GIORNO_FINE >= :pDaGiornoFine AND
                            aggi.GIORNO_FINE <= :pAGiornoFine AND
                            (
                                :pValidImportoMassimo = 0 OR
                                (:pValidImportoMassimo = 1 AND (aggi.IMPORTO_MASSIMO >= :pDaImportoMassimo AND aggi.IMPORTO_MASSIMO <= :pAImportoMassimo))
                            )
                            
                            ORDER BY aggi.TIPO_TRIBUTO  ASC,
                                     aggi.DATA_INIZIO   ASC,
                                     aggi.DATA_FINE     ASC,
                                     aggi.giorno_inizio ASC,
                                     aggi.giorno_fine   ASC,
                                     aggi.SEQUENZA      ASC

                           """

        return sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }
    }

    def existsOverlappingAggio(Aggio aggio) {
        return Aggio.createCriteria().count {

            eq('tipoTributo', aggio.tipoTributo)

            // Avoiding to involve current interesse when editing it
            if (aggio.sequenza != null) {
                ne('sequenza', aggio.sequenza)
            }

            ge('dataFine', aggio.dataInizio)
            le('dataInizio', aggio.dataFine)

            ge('giornoFine', aggio.giornoInizio)
            le('giornoInizio', aggio.giornoFine)
        } > 0
    }

    def salvaAggio(Aggio aggio) {
        aggio.save(failOnError: true, flush: true)
    }

    def eliminaAggio(Aggio aggio) {
        aggio.delete(failOnError: true, flush: true)
    }

    def getAggio(def tipoTributo, def sequenza) {
        return Aggio.createCriteria().get {
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
        sql.call('{call AGGI_NR(?, ?)}',
                [
                        tipoTributo,
                        Sql.NUMERIC
                ],
                { newSequenza = it }
        )

        return newSequenza
    }


}