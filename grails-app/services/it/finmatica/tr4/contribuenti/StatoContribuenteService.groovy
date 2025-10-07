package it.finmatica.tr4.contribuenti

import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.StatoContribuente
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.StatoContribuenteDTO
import it.finmatica.tr4.dto.TipoStatoContribuenteDTO
import it.finmatica.tr4.dto.TipoTributoDTO
import org.hibernate.FetchMode
import org.hibernate.SessionFactory

class StatoContribuenteService {

    SessionFactory sessionFactory
    CommonService commonService
    TipoStatoContribuenteService tipoStatoContribuenteService

    int countStatiContribuente(def filter) {
        if (filter.tipiTributo == null || filter.tipiTributo.isEmpty()) {
            return 0
        }

        return StatoContribuente.createCriteria().count {
            eq('contribuente.codFiscale', filter.codFiscale)
            inList('tipoTributo.tipoTributo', filter.tipiTributo)
        }
    }

    def findStatiContribuente(Map filter, Map params = [:]) {

        if (filter.tipiTributo == null || filter.tipiTributo.isEmpty()) {
            return [list: [], totalCount: 0]
        }

        params.max = params?.max ?: Long.MAX_VALUE
        params.offset = (params.activePage ?: 0) * params.max

        def fromWhereClause = " FROM StatoContribuente stco " +
                " WHERE stco.contribuente.codFiscale = :codFiscale" +
                " AND stco.tipoTributo.tipoTributo in :tipiTributo"
        def args = [codFiscale: filter.codFiscale, tipiTributo: filter.tipiTributo]

        def result = StatoContribuente.executeQuery(
                """SELECT stco
                            $fromWhereClause
                            ORDER BY 
                                stco.tipoTributo,
                                stco.dataStato DESC
                """,
                [*: args, max: params.max, offset: params.offset]
        )

        def totalCount = StatoContribuente.executeQuery(
                """SELECT count(stco)
                            $fromWhereClause""",
                args)[0]

        return [list: result.iterator().toList().toDTO(['stato']), totalSize: totalCount]
    }

    def findLatestStatiContribuenteIds(def codFiscaleList = null) {
        def sqlQuery = """
            select ordered_stco.id
              from (select stco.*,
                           rank() over(partition by stco.cod_fiscale, stco.tipo_tributo order by stco.data_stato desc, stco.id desc) order_index
                      from stati_contribuente stco """
        if (codFiscaleList?.any { it != null }) {
            sqlQuery += "where stco.cod_fiscale in (:codFiscaleList)"
        }
        sqlQuery += """
              ) ordered_stco
             where ordered_stco.order_index = 1
        """
        def latestIds = sessionFactory.currentSession.createSQLQuery(sqlQuery).with {
            if (codFiscaleList?.any { it != null }) {
                setParameterList('codFiscaleList', codFiscaleList)
            }
            list()
        }.collect { it as Long }
        return latestIds
    }

    def findLatestStatiContribuente(def codFiscaleList) {
        def latestIds = findLatestStatiContribuenteIds(codFiscaleList)
        if (latestIds.isEmpty()) {
            return []
        }

        return StatoContribuente.createCriteria().list {
            fetchMode('stato', FetchMode.JOIN)
            inList('id', latestIds)
        }.toDTO()
    }

    def getStatiContribuenteDescription(def statoContribuenteList) {
        def result = [:]
        statoContribuenteList.each {
            if (!result.containsKey(it.contribuente.codFiscale)) {
                result[it.contribuente.codFiscale] = [:]
            }
            result[it.contribuente.codFiscale] << [(it.tipoTributo.tipoTributo): it.stato.descrizioneBreve]
        }
        return result
    }

    def existsStatoContribuente(StatoContribuenteDTO statoContribuente) {
        return StatoContribuente.createCriteria().count {
            if (statoContribuente.id) {
                ne('id', statoContribuente.id)
            }
            eq('contribuente.codFiscale', statoContribuente.contribuente.codFiscale)
            eq('tipoTributo.tipoTributo', statoContribuente.tipoTributo.tipoTributo)
            // eq('stato.id', statoContribuente.stato.id)
            eq('dataStato', statoContribuente.dataStato)
            eq('anno', statoContribuente.anno)
        } > 0
    }

    def saveStatoContribuente(StatoContribuenteDTO statoContribuente) {
        return statoContribuente
                .toDomain()
                .save(flush: true, failOnError: true)
                .toDTO()
    }

    void deleteStatoContribuente(StatoContribuenteDTO statoContribuente) {
        statoContribuente.toDomain().delete()
    }

    def listTipiStatoContribuente() {
        tipoStatoContribuenteService.listTipiStatoContribuente()
    }

    def existsAnyTipoStatoContribuente() {
        tipoStatoContribuenteService.existsAnyTipoStatoContribuente()
    }

    def createStatoContribuente(Map params) {
        def result = new StatoContribuenteDTO()

        result.contribuente = Contribuente.findByCodFiscale((String) params.codFiscale).toDTO()
        result.tipoTributo = (TipoTributoDTO) params.tipoTributo
        result.stato = (TipoStatoContribuenteDTO) params.tipoStatoContribuente
        result.dataStato = new Date()

        return result
    }

    def getStatoContribuente(StatoContribuenteDTO original) {
        return commonService.clona(original)
    }
}
