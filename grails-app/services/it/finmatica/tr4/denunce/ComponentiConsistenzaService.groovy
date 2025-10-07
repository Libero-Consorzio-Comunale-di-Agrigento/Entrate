package it.finmatica.tr4.denunce


import grails.transaction.Transactional
import org.hibernate.SessionFactory
import transform.AliasToEntityCamelCaseMapResultTransformer

@Transactional
class ComponentiConsistenzaService {

    SessionFactory sessionFactory

    def getListaDati(def filtri, def ordinamentoSelezionato = "Alfabetico") {

        def parametri = [:]
        def ordinamentoQuery = ""

        parametri << ['p_situazione_al': filtri.situazioneAl ?: new Date()]
        parametri << ['p_ordina': ordinamentoSelezionato]
        parametri << ['p_componenti_da': filtri.componentiDa ?: 0]
        parametri << ['p_componenti_a': filtri.componentiA ?: 999999]
        parametri << ['p_consistenza_da': filtri.consistenzaDa ?: 0.00]
        parametri << ['p_consistenza_a': filtri.consistenzaA ?: 999999.99]
        parametri << ['p_flag_ap': filtri.flagAp ? 'S' : '%']


        switch (ordinamentoSelezionato) {
            case "Alfabetico":
                ordinamentoQuery = " order by sogg.cognome, sogg.nome "
                break
            case "Codice Fiscale":
                ordinamentoQuery = " order by ogva.cod_fiscale "
                break
            case "Numero Componenti":
                ordinamentoQuery = " order by f_numero_familiari_al(sogg.ni, :p_situazione_al) desc"
                break
            case "Consistenza":
                ordinamentoQuery = " order by ogpr.consistenza"
                break
        }

        def query = """
                            select ogva.cod_fiscale,
                                   ogva.oggetto_pratica,
                                   ogva.oggetto,
                                   ogva.dal,
                                   ogva.al,
                                   ogva.pratica,
                                   ogva.numero,
                                   ogva.data,
                                   ogva.anno,
                                   ogva.tipo_pratica,
                                   ogva.tipo_evento,
                                   translate(sogg.cognome_nome, '/', ' ') cognome_nome,
                                   f_numero_familiari_al(sogg.ni, :p_situazione_al) componenti,
                                   sogg.cognome,
                                   sogg.nome,
                                   ogpr.consistenza,
                                   ogpr.tributo,
                                   ogpr.categoria,
                                   cate.descrizione,
                                   ogpr.tipo_tariffa,
                                   tari.descrizione,
                                   ogco.flag_ab_principale,
                                   'Situazione al ' || to_char(:p_situazione_al, 'dd/mm/yyyy') data_riferimento,
                                   lpad(:p_ordina, 4, ' ') ordinamento
                              from soggetti             sogg,
                                   contribuenti         cont,
                                   tariffe              tari,
                                   categorie            cate,
                                   oggetti              ogge,
                                   oggetti_pratica      ogpr,
                                   oggetti_contribuente ogco,
                                   oggetti_validita     ogva
                             where ogpr.oggetto_pratica = ogva.oggetto_pratica
                               and cate.tributo(+) = ogpr.tributo
                               and cate.categoria(+) = ogpr.categoria
                               and tari.tributo(+) = ogpr.tributo
                               and tari.categoria(+) = ogpr.categoria
                               and tari.tipo_tariffa(+) = ogpr.tipo_tariffa
                               and tari.anno(+) = to_number(to_char(:p_situazione_al, 'yyyy'))
                               and ogco.cod_fiscale = ogva.cod_fiscale
                               and ogco.oggetto_pratica = ogva.oggetto_pratica
                               and cont.cod_fiscale = ogva.cod_fiscale
                               and ogge.oggetto = ogpr.oggetto
                               and sogg.ni = cont.ni
                               and :p_situazione_al between nvl(ogva.dal, to_date('2222222', 'j')) and
                                   nvl(ogva.al, to_date('3333333', 'j'))
                               and f_numero_Familiari_al(sogg.ni, :p_situazione_al) between
                                   :p_componenti_da and :p_componenti_a
                               and ogpr.consistenza between :p_consistenza_da and :p_consistenza_a
                               and ogva.tipo_tributo = 'TARSU'
                               and ogge.cod_via = sogg.cod_via
                               and cate.flag_domestica = 'S'
                               and nvl(ogco.flag_ab_principale, ' ') like :p_flag_ap
                               ${ordinamentoQuery}
                           """


        def result = sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        return result
    }
}
