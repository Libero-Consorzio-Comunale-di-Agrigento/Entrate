package it.finmatica.tr4.bonificaDati

import grails.transaction.Transactional
import it.finmatica.tr4.anomalie.AnomaliaIci
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TipoIntervento
import org.hibernate.SQLQuery
import org.hibernate.SessionFactory
import transform.AliasToEntityCamelCaseMapResultTransformer

import java.sql.Timestamp

@Transactional
class AnomaliaMuiService {
    SessionFactory sessionFactory
    CommonService commonService

    def getAnomalieMUI(def filter) {
        def sqlAnomalieIci = """
            select distinct 
                    null as id,
                    max(ogpr.valore) over(partition by anic.anno, anic.tipo_anomalia) valore_massimo,
                    avg(ogpr.valore) over(partition by anic.anno, anic.tipo_anomalia) valore_medio,
                    null as categorie,
                    null as data_variazione,
                    null as flag_imposta,
                    null as rendita_da,
                    null as rendita_a,
                    null as scarto,
                    f_descrizione_titr(prtr.tipo_tributo, anic.anno) as tipo_tributo,
                    prtr.tipo_tributo as tipo_tributo_org,
                    null as utente,
                    null as nominativo_utente,
                    tian.tipo_intervento as tipo_intervento,
                    tian.tipo_anomalia as tipo_anomalia,
                    tian.descrizione as descrizione,
                    tian.zul as pannello,
                    anic.anno,
                    max(f_rendita(a_valore            => ogpr.valore,
                              a_tipo_ogge         => ogpr.tipo_oggetto,
                              a_anno_dic          => ogpr.anno,
                              a_categoria_catasto => ogpr.categoria_catasto)) over(partition by anic.anno, anic.tipo_anomalia) rendita_massima,
                    avg(f_rendita(a_valore            => ogpr.valore,
                              a_tipo_ogge         => ogpr.tipo_oggetto,
                              a_anno_dic          => ogpr.anno,
                              a_categoria_catasto => ogpr.categoria_catasto)) over(partition by anic.anno, anic.tipo_anomalia) rendita_media,
                    sum(decode(nvl(anic.flag_ok, 'N'), 'S', 1, 0)) over(partition by anic.anno, anic.tipo_anomalia) as num_oggetti,
                    count(*) over(partition by anic.anno, anic.tipo_anomalia) as num_tot_oggetti,
                    1 as visibile
                from anomalie_ici anic, 
                     oggetti ogge,
                     oggetti_pratica ogpr,
                     tipi_anomalia tian,
                     pratiche_tributo prtr
            where anic.oggetto = ogge.oggetto
                    and ogge.oggetto = ogpr.oggetto
                    and ogpr.pratica = prtr.pratica
                    and anic.tipo_anomalia = tian.tipo_anomalia
        """

        def whereClauses
        def queryParams
        (whereClauses, queryParams) = getWhereClausesAndParameters(filter)
        sqlAnomalieIci += whereClauses

        SQLQuery anomalieIciQuery = getParametrizedQuery(sqlAnomalieIci, queryParams)

        def listaAnomalieIci = anomalieIciQuery.list()

        return listaAnomalieIci.collect { anomalia ->
            anomalia.id = anomalia.id as Long
            anomalia.dataVariazione = anomalia.dataVariazione as Timestamp
            anomalia.tipoIntervento = TipoIntervento.PRATICA
            anomalia.tipoAnomalia = anomalia.tipoAnomalia as Short
            anomalia.anno = anomalia.anno as Short
            anomalia.numOggetti = anomalia.numOggetti as Integer
            anomalia.numTotOggetti = anomalia.numTotOggetti as Integer
            anomalia.visibile = anomalia.visibile as Integer
            return anomalia
        }
    }

    def getDettagliAnomaliaOggettiAndPratiche(def filter) {
        def sqlOggetti = """
                select distinct 
                       anic.flag_ok as flag_ok,
                       anic.anomalia as id_anomalia,
                       ogge.tipo_oggetto as tipo_oggetto,
                       ogge.oggetto as id_oggetto,
                       nvl(arvi.denom_uff, nvl(ogge.indirizzo_localita, ' ')) ||
                       decode(ogge.num_civ, null, '', ', ' || ogge.num_civ) ||
                       decode(ogge.suffisso, null, '', '/' || ogge.suffisso) ||
                       decode(ogge.scala, null, '', ' Sc:' || ogge.scala) ||
                       decode(ogge.piano, null, '', ' P:' || ogge.piano) ||
                       decode(ogge.interno, null, '', ' int. ' || ogge.interno) as indirizzo,
                       ogge.categoria_catasto as categoria_catasto,
                       ogge.classe_catasto as classe_catasto,
                       ogge.sezione as sezione,
                       ogge.foglio as foglio,
                       ogge.numero as numero,
                       ogge.zona as zona,
                       ogge.subalterno as subalterno,
                       ogge.protocollo_catasto as protocollo_catasto,
                       ogge.anno_catasto as anno_catasto,
                       ogge.partita as partita,
                       max(ogpr.valore) over(partition by anic.anno, anic.tipo_anomalia) as valore_massimo,
                       avg(ogpr.valore) over(partition by anic.anno, anic.tipo_anomalia) as valore_medio,
                       max(f_rendita(a_valore            => ogpr.valore,
                                     a_tipo_ogge         => ogpr.tipo_oggetto,
                                     a_anno_dic          => ogpr.anno,
                                     a_categoria_catasto => ogpr.categoria_catasto)) over(partition by anic.anno, anic.tipo_anomalia) as rendita_massima,
                       avg(f_rendita(a_valore            => ogpr.valore,
                                     a_tipo_ogge         => ogpr.tipo_oggetto,
                                     a_anno_dic          => ogpr.anno,
                                     a_categoria_catasto => ogpr.categoria_catasto)) over(partition by anic.anno, anic.tipo_anomalia) as rendita_media,
                       count(distinct ogge.oggetto) over() as total_count
                  from anomalie_ici       anic,
                       oggetti            ogge,
                       oggetti_pratica    ogpr,
                       tipi_anomalia      tian,
                       pratiche_tributo   prtr,
                       archivio_vie       arvi
                 where anic.oggetto = ogge.oggetto
                   and ogge.oggetto = ogpr.oggetto
                   and ogpr.pratica = prtr.pratica
                   and ogge.cod_via = arvi.cod_via (+)
                   and anic.tipo_anomalia = tian.tipo_anomalia"""


        def whereClauses
        def queryParams
        (whereClauses, queryParams) = getWhereClausesAndParameters(filter)
        sqlOggetti += whereClauses

        sqlOggetti += getOrderByClause(filter.ordinamento)

        def dettagliOggettiQuery = getParametrizedQuery(sqlOggetti, queryParams)

        def rawDettagliOggetti = dettagliOggettiQuery.with {

            setFirstResult(filter.activePage * filter.pageSize)
            setMaxResults(filter.activePage + 1 * filter.pageSize)

            list()
        }

        filter.oggetti = rawDettagliOggetti.collect { it.idOggetto } as List<Long>

        def pratiche = getDettagliAnomaliaPraticheForOggetto(filter)

        def dettagliOggetti = rawDettagliOggetti.collect { item ->
            item.praticheCorrette = pratiche[item.idOggetto as Long].correct
            item.dettagli = pratiche[item.idOggetto as Long].list
            return item
        }

        def totalCount = (rawDettagliOggetti && !rawDettagliOggetti.isEmpty()) ? rawDettagliOggetti.first().totalCount : 0

        return [list : dettagliOggetti,
                total: totalCount]
    }

    def cambiaStatoAnomalia(def idAnomalia, def stato) {
        def anom = AnomaliaIci.get(idAnomalia)
        anom.flagOk = stato
        anom.save(flush: true, failOnError: true)
    }

    private def getDettagliAnomaliaPraticheForOggetto(def filter) {
        String sqlPratiche = """
                select distinct
                       anic.anomalia as id_anomalia,
                       ogge.oggetto as id_oggetto,
                       null as flag_ok,
                       ogpr.tipo_oggetto as tipo_oggetto,
                       prtr.pratica as id_pratica,
                       ogpr.num_ordine as num_ordine,
                       prtr.tipo_tributo as tipo_tributo,
                       prtr.anno as anno,
                       ogco.tipo_rapporto as tipo_rapporto,
                       sogg.cognome_nome as cognome_nome,
                       ogco.cod_fiscale as cod_fiscale,
                       ogpr.categoria_catasto as categoria_catasto,
                       ogpr.classe_catasto as classe_catasto,
                       ogco.mesi_possesso as mesi_possesso,
                       ogco.perc_possesso as perc_possesso,
                       ogco.flag_possesso as flag_possesso,
                       ogco.flag_esclusione as flag_esclusione,
                       ogpr.valore as valore,
                       f_rendita(a_valore            => ogpr.valore,
                                 a_tipo_ogge         => ogpr.tipo_oggetto,
                                 a_anno_dic          => ogpr.anno,
                                 a_categoria_catasto => ogpr.categoria_catasto) as rendita,
                       ogpr.oggetto_pratica as id_oggetto_pratica,
                       anic.anomalia as id_anomalia_pratica,
                       count(*) over(partition by ogge.oggetto) as by_oggetto_count,
                       count(anic.flag_ok) over(partition by ogge.oggetto) as flag_ok_count
                  from anomalie_ici         anic,
                       oggetti              ogge,
                       oggetti_pratica      ogpr,
                       oggetti_contribuente ogco,
                       tipi_anomalia        tian,
                       pratiche_tributo     prtr,
                       rapporti_tributo     ratr,
                       contribuenti         cont,
                       soggetti             sogg,
                       archivio_vie         arvi
                 where anic.oggetto = ogge.oggetto
                   and ogge.oggetto = ogpr.oggetto
                   and ogpr.pratica = prtr.pratica
                   and prtr.pratica = ratr.pratica
                   and ogco.oggetto_pratica = ogpr.oggetto_pratica
                   and ogco.cod_fiscale = cont.cod_fiscale
                   and cont.ni = sogg.ni
                   and ogge.cod_via = arvi.cod_via (+)
                   and anic.tipo_anomalia = tian.tipo_anomalia
                   and prtr.tipo_pratica = 'D' 
            """

        def whereClauses
        def queryParams
        (whereClauses, queryParams) = getWhereClausesAndParameters(filter)
        sqlPratiche += whereClauses

        def praticheQuery = getParametrizedQuery(sqlPratiche, queryParams)

        def rawListaPratiche = praticheQuery.list()

        def praticheForOggetto = [:]
        rawListaPratiche.each { item ->
            item.flagPossesso = item.flagPossesso == 'S'
            item.flagEsclusione = item.flagEsclusione == 'S'

            def idOggetto = item.idOggetto as Long
            if (!praticheForOggetto.containsKey(idOggetto)) {
                praticheForOggetto.put(idOggetto, [total  : item.byOggettoCount,
                                                   correct: item.flagOkCount,
                                                   list   : []])
            }
            praticheForOggetto[idOggetto].list.add(item)
        }

        return praticheForOggetto
    }

    private def getWhereClausesAndParameters(def filter) {
        def whereClauses = ""
        def params = [:]
        if (filter.tipiAnomalia && !filter.tipiAnomalia.empty) {
            whereClauses += " and tian.tipo_anomalia in (:tipiAnomalia) \n"
            params.tipiAnomalia = filter.tipiAnomalia
        }
        if (filter.tipiTributo && !filter.tipiTributo.empty) {
            whereClauses += " and prtr.tipo_tributo in (:tipiTributo) \n"
            params.tipiTributo = filter.tipiTributo
        }
        if (filter.tipiPratiche && !filter.tipiPratiche.empty) {
            whereClauses += " and prtr.tipo_pratica in (:tipiPratiche) \n"
            params.tipiPratiche = filter.tipiPratiche
        }
        if (filter.anno) {
            whereClauses += " and anic.anno = :anno \n"
            params.anno = filter.anno
        }
        if (filter.oggetti && !filter.oggetti.isEmpty()) {
            whereClauses += "	and ogge.oggetto in (:oggetti) \n"
            params.oggetti = filter.oggetti
        }
        if (filter.tipoOggetto) {
            whereClauses += " and ogge.tipo_oggetto = :tipoOggetto  \n"
            params.tipoOggetto = filter.tipoOggetto
        }
        if (filter.categoriaCatasto) {
            whereClauses += " and ogge.categoria_catasto = :categoriaCatasto \n"
            params.categoriaCatasto = filter.categoriaCatasto
        }
        if (filter.stato == "1") {
            whereClauses += " and anic.flag_ok is null \n"
        } else if (filter.stato == "2") {
            whereClauses += " and anic.flag_ok = 'S' \n"
        }

        return [whereClauses, params]
    }

    private def getOrderByClause(Map ordinamento) {
        def orderByMap = []

        ordinamento.each { k, v ->
            if (!v.verso || v.posizione <= 0) {
                return
            }

            def splits = k.split('\\.')
            String camelCaseName = splits[splits.size() - 1]
            switch (camelCaseName) {
                case "id":
                    camelCaseName = 'idOggetto'
                    break
            }
            orderByMap << [campo    : camelCaseName,
                           verso    : v.verso == 'A' ? 'asc' : 'desc',
                           posizione: v.posizione]
        }

        orderByMap.sort { a, b -> a.posizione <=> b.posizione
        }

        def orderByClause = ""
        if (orderByMap) {
            orderByClause += " order by \n"
            orderByMap.eachWithIndex { it, index ->
                if (index != 0) {
                    orderByClause += " ,"
                }
                orderByClause += " $it.campo $it.verso \n"
            }
        }
        return orderByClause
    }

    private def getParametrizedQuery(String sql, Map queryParams) {
        def query = sessionFactory.currentSession.createSQLQuery(sql)

        query.setResultTransformer(AliasToEntityCamelCaseMapResultTransformer.INSTANCE)

        queryParams.each { param, value ->
            if (value instanceof List) {
                query.setParameterList(param as String, value as List)
            } else {
                query.setParameter(param as String, value)
            }
        }

        return query
    }

}
