package it.finmatica.tr4.contribuenti

import grails.transaction.Transactional
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.commons.TipoEventoDenuncia
import it.finmatica.tr4.commons.TipoOccupazione
import it.finmatica.tr4.dto.CodiceTributoDTO
import it.finmatica.tr4.pratiche.CampiOrdinamento
import transform.AliasToEntityCamelCaseMapResultTransformer

import javax.annotation.PostConstruct

@Transactional
class UtenzeService {

    def sessionFactory

    static def TIPI_ABITAZIONE = [
            P : "Principale",
            NP: "Non Principale",
            T : "(Tutte)"
    ]
    static def DEFAULT_TIPO_ABITAZIONE = TIPI_ABITAZIONE.entrySet()[2]

    static def TIPI_OCCUPAZIONE = [
            TipoOccupazione.P.properties,
            TipoOccupazione.T.properties,
            [tipoOccupazione: "X", descrizione: ""]
    ]
    static def DEFAULT_TIPO_OCCUPAZIONE = TIPI_OCCUPAZIONE[0]

    static def TIPI_EVENTO =
            TipoEventoDenuncia.values()
                    .findAll { it.tipoEventoDenuncia in ['I', 'V', 'C', 'U'] }*.properties +
                    [tipoEventoDenuncia: "X", descrizione: "(Tutti)"]
    static def DEFAULT_TIPO_EVENTO = TIPI_EVENTO[4]

    static def DEFAULT_CODICE_TRIBUTO = new CodiceTributoDTO([id: 0, descrizione: "(Tutti)"])
    static def CODICI_TRIBUTO = []


    static Boolean DEFAULT_FLAG_CONTENZIOSO = false
    static Boolean DEFAULT_FLAG_INCL_CESSATI = false
    static String ALL_FISCAL_CODE = "%"
    static String NO_USERS_FOUND = "noUserFound"

    @PostConstruct
    void postInit() {
        CODICI_TRIBUTO = [DEFAULT_CODICE_TRIBUTO] +
                OggettiCache.CODICI_TRIBUTO.valore.findAll { it?.tipoTributo?.tipoTributo == 'TARSU' }
                        .sort { it.id }
    }


    def controlloUtenze(String codiceFiscale, String anno, int pageSize, int activePage) {

        def query = getQueryPerControlloUtenze(codiceFiscale, anno)

        // properties per la paginazione
        int pageStart = activePage * pageSize

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(query)

        sqlQuery.setInteger("p_anno", anno as Integer)
        sqlQuery.setString("p_cf", codiceFiscale)
        sqlQuery.setLong("p_ruolo", -1)
        sqlQuery.setResultTransformer(AliasToEntityCamelCaseMapResultTransformer.INSTANCE)
        sqlQuery.setFirstResult(pageStart)
        sqlQuery.setMaxResults(pageSize)

        def listaUtenzeTariFromDB = sqlQuery.list()

        if (pageSize == Integer.MAX_VALUE) {
            return [lista: listaUtenzeTariFromDB, totaleUtenze: 0]
        }

        String queryCount = """
            select count(*) as totale_Utenze from ($query)
        """

        sqlQuery = sessionFactory.currentSession.createSQLQuery(queryCount)

        sqlQuery.setInteger("p_anno", anno as Integer)
        sqlQuery.setString("p_cf", codiceFiscale)
        sqlQuery.setLong("p_ruolo", -1)
        sqlQuery.setResultTransformer(AliasToEntityCamelCaseMapResultTransformer.INSTANCE)

        List totali = sqlQuery.list()

        return [lista: listaUtenzeTariFromDB, totaleUtenze: totali[0].totaleUtenze as Integer]

    }


    private String getQueryPerControlloUtenze(String codiceFiscale, String anno) {

        String query = """
        SELECT sogg.ni,
               cont.cod_fiscale,
               sogg.cognome_nome,
               cate.tributo,
               cate.categoria,
               'Mancano i coefficienti domestici x abitazione principale' messaggio
          FROM (select max(numero_familiari) max_fam
                  from coefficienti_domestici
                 where anno = :p_anno) max_fam,
               familiari_soggetto faso,
               pratiche_tributo prtr,
               oggetti_pratica ogpr,
               oggetti_contribuente ogco,
               categorie cate,
               soggetti sogg,
               contribuenti cont,
               (select ruolo, data_emissione
                  from ruoli
                 where ruolo = :p_ruolo
                union
                /* se non abbiamo il ruolo (ci viene passato -1) usiamo la data di sistema*/
                select :p_ruolo, trunc(sysdate)
                  from dual
                 where :p_ruolo = -1) ruol
         where faso.ni = sogg.ni
           and faso.anno = :p_anno
           and sogg.ni = cont.ni
           and cate.flag_domestica = 'S'
           and cate.tributo = ogpr.tributo
           and cate.categoria = ogpr.categoria
           and ogpr.oggetto_pratica = ogco.oggetto_pratica
           and ogco.cod_fiscale = cont.cod_fiscale
           and ruol.ruolo = :p_ruolo
           and prtr.pratica = ogpr.pratica
           and (prtr.tipo_pratica = 'D' or
               prtr.tipo_pratica = 'A' and prtr.flag_adesione = 'S' and
               prtr.data_notifica is not null or
               prtr.tipo_pratica = 'A' and prtr.flag_adesione is null and
               ruol.data_emissione - prtr.data_notifica > 60)
           and cont.cod_fiscale like :p_cf
           and exists
         (select 1
                  from oggetti_validita ogva
                 where nvl(to_char(ogva.dal, 'yyyy'), :p_anno) <= :p_anno
                   and nvl(to_char(ogva.al, 'yyyy'), :p_anno) >= :p_anno
                   and ogva.cod_fiscale = cont.cod_fiscale
                   and ogva.oggetto_pratica = ogpr.oggetto_pratica)
           and not exists
         (select 1
                  from coefficienti_domestici
                 where coefficienti_domestici.anno = faso.anno
                   and coefficienti_domestici.numero_familiari =
                       decode(sign(faso.numero_familiari - max_fam.max_fam),
                              1,
                              max_fam.max_fam,
                              faso.numero_familiari))
           and (ogco.flag_ab_principale = 'S' or
               ogco.flag_ab_principale is null and not exists
                (select 1 from componenti_superficie where anno = :p_anno))
        union
        SELECT sogg.ni,
               cont.cod_fiscale,
               sogg.cognome_nome,
               cate.tributo,
               cate.categoria,
               'Mancano i coefficienti domestici x abitazione non principale'
          FROM (select max(numero_familiari) max_fam
                  from componenti_superficie
                 where anno = :p_anno) max_fam,
               componenti_superficie cosu,
               pratiche_tributo prtr,
               oggetti_pratica ogpr,
               oggetti_contribuente ogco,
               categorie cate,
               soggetti sogg,
               contribuenti cont,
               (select ruolo, data_emissione
                  from ruoli
                 where ruolo = :p_ruolo
                union
                select :p_ruolo, trunc(sysdate)
                  from dual
                 where :p_ruolo = -1) ruol
         where cosu.anno = :p_anno
           and sogg.ni = cont.ni
           and cate.flag_domestica = 'S'
           and cate.tributo = ogpr.tributo
           and cate.categoria = ogpr.categoria
           and ogpr.oggetto_pratica = ogco.oggetto_pratica
           and ogco.cod_fiscale = cont.cod_fiscale
           and ruol.ruolo = :p_ruolo
           and prtr.pratica = ogpr.pratica
           and (prtr.tipo_pratica = 'D' or
               prtr.tipo_pratica = 'A' and prtr.flag_adesione = 'S' and
               prtr.data_notifica is not null or
               prtr.tipo_pratica = 'A' and prtr.flag_adesione is null and
               ruol.data_emissione - prtr.data_notifica > 60)
           and cont.cod_fiscale like :p_cf
           and exists
         (select 1
                  from oggetti_validita ogva
                 where nvl(to_char(ogva.dal, 'yyyy'), :p_anno) <= :p_anno
                   and nvl(to_char(ogva.al, 'yyyy'), :p_anno) >= :p_anno
                   and ogva.cod_fiscale = cont.cod_fiscale
                   and ogva.oggetto_pratica = ogpr.oggetto_pratica)
           and not exists
         (select 1
                  from coefficienti_domestici
                 where coefficienti_domestici.anno = cosu.anno
                   and coefficienti_domestici.numero_familiari =
                       decode(sign(cosu.numero_familiari - max_fam.max_fam),
                              1,
                              max_fam.max_fam,
                              cosu.numero_familiari))
           and ogco.flag_ab_principale is null
           and exists
         (select 1 from componenti_superficie where anno = :p_anno)
        union
        SELECT sogg.ni,
               cont.cod_fiscale,
               sogg.cognome_nome,
               cate.tributo,
               cate.categoria,
               decode(ogco.flag_ab_principale,
                      'S',
                      'I familiari indicati non coprono l''intero periodo di validita'' dell''oggetto',
                      'Mancano i componenti superficie')
          FROM categorie cate,
               oggetti_pratica ogpr,
               pratiche_tributo prtr,
               oggetti_contribuente ogco,
               soggetti sogg,
               contribuenti cont,
               (select ruolo, data_emissione
                  from ruoli
                 where ruolo = :p_ruolo
                union
                select :p_ruolo, trunc(sysdate)
                  from dual
                 where :p_ruolo = -1) ruol
         where cate.tributo = ogpr.tributo
           and cate.categoria = ogpr.categoria
           and cate.flag_domestica = 'S'
           and sogg.ni = cont.ni
           and ogpr.oggetto_pratica = ogco.oggetto_pratica
           and ogco.cod_fiscale = cont.cod_fiscale
           and cont.cod_fiscale like :p_cf
           and ruol.ruolo = :p_ruolo
           and prtr.pratica = ogpr.pratica
           and (prtr.tipo_pratica = 'D' or
               prtr.tipo_pratica = 'A' and prtr.flag_adesione = 'S' and
               prtr.data_notifica is not null or
               prtr.tipo_pratica = 'A' and prtr.flag_adesione is null and
               ruol.data_emissione - prtr.data_notifica > 60)
           and exists
         (select 1
                  from oggetti_validita ogva
                 where nvl(to_char(ogva.dal, 'yyyy'), :p_anno) <= :p_anno
                   and nvl(to_char(ogva.al, 'yyyy'), :p_anno) >= :p_anno
                   and ogva.cod_fiscale = cont.cod_fiscale
                   and ogva.oggetto_pratica = ogpr.oggetto_pratica)
           and ((ogco.flag_ab_principale = 'S' and exists
                (select 1
                    from oggetti_validita ogva
                   where nvl(to_char(ogva.dal, 'yyyy'), :p_anno) <= :p_anno
                     and nvl(to_char(ogva.al, 'yyyy'), :p_anno) >= :p_anno
                     and ogva.cod_fiscale = cont.cod_fiscale
                     and ogva.oggetto_pratica = ogpr.oggetto_pratica
                     and f_test_copertura_faso(cont.ni,
                                               greatest(nvl(ogva.dal,
                                                            to_date('01/01/' || :p_anno,
                                                                    'dd/mm/yyyy')),
                                                        to_date('01/01/' || :p_anno,
                                                                'dd/mm/yyyy')),
                                               least(nvl(ogva.al,
                                                         to_date('31/12/' || :p_anno,
                                                                 'dd/mm/yyyy')),
                                                     to_date('31/12/' || :p_anno,
                                                             'dd/mm/yyyy')),:p_anno) = 'N')) or
               (ogco.flag_ab_principale is null and not exists
                (select 1 from componenti_superficie where anno = :p_anno)))
"""

        return query

    }


    def getQueryPerUtenzeTari(def filterParam) {


        def filtri = [:]

        String sqlFiltri = ""

        if (filterParam.flagContenzioso != DEFAULT_FLAG_CONTENZIOSO) {
            sqlFiltri += " and  OGPR.FLAG_CONTENZIOSO = 'S'"
        }

        if (filterParam.flagInclCessati == DEFAULT_FLAG_INCL_CESSATI) {
            sqlFiltri += " AND nvl(to_number(to_char(OGVA.AL,'yyyy')),TARI.ANNO) >= TARI.ANNO "
        } else {
            sqlFiltri += " AND (nvl(to_number(to_char(OGVA.AL, 'yyyy')), TARI.ANNO) >= TARI.ANNO OR"
            sqlFiltri += " to_number(to_char(OGVA.AL, 'yyyy')) <= TARI.ANNO)"
        }


        if (filterParam.tipoAbitazione == TIPI_ABITAZIONE.entrySet()[0]) {
            sqlFiltri += " and ogco.flag_ab_principale is not null "
        } else if (filterParam.tipoAbitazione == TIPI_ABITAZIONE.entrySet()[1]) {
            sqlFiltri += " and ogco.flag_ab_principale is null "
        }

        if (filterParam.statoSoggetti == "D") {
            sqlFiltri += " AND nvl(SOGGETTI.STATO,0) = 50 "
        }

        if (filterParam.statoSoggetti == "ND") {
            sqlFiltri += " AND nvl(SOGGETTI.STATO,0)  <> 50 "
        }

        if (filterParam.statoUtenze == "ND") {
            sqlFiltri += " and cate.flag_domestica is null"
        }

        if (filterParam.statoUtenze == "D") {
            sqlFiltri += " and cate.flag_domestica is not null"
        }

        if (filterParam.tipoOccupazione == DEFAULT_TIPO_OCCUPAZIONE) {
            filterParam.tipoOccupazione = TIPI_OCCUPAZIONE[0]
        }
        filtri << ['p_anno': filterParam.anno]
        filtri << ['p_tipoOccupazione': filterParam.tipoOccupazione.tipoOccupazione]

        if (filterParam.numeroCivicoDa != null) {
            filtri << ['p_numeroCivicoDa': filterParam.numeroCivicoDa]
            sqlFiltri += " AND OGGE.NUM_CIV >= :p_numeroCivicoDa"
        }
        if (filterParam.numeroCivicoA != null) {
            filtri << ['p_numeroCivicoA': filterParam.numeroCivicoA]
            sqlFiltri += " AND OGGE.NUM_CIV <= :p_numeroCivicoA"
        }
        if (filterParam.categoriaDa != null) {
            filtri << ['p_categoriaDa': filterParam.categoriaDa]
            sqlFiltri += " AND OGPR.CATEGORIA >= :p_categoriaDa "
        }
        if (filterParam.categoriaA != null) {
            filtri << ['p_categoriaA': filterParam.categoriaA]
            sqlFiltri += " AND OGPR.CATEGORIA <= :p_categoriaA "
        }
        if (filterParam.tariffaDa != null) {
            filtri << ['p_tariffaDa': filterParam.tariffaDa]
            sqlFiltri += " AND OGPR.TIPO_TARIFFA >= :p_tariffaDa"
        }
        if (filterParam.tariffaA != null) {
            filtri << ['p_tariffaA': filterParam.tariffaA]
            sqlFiltri += " AND OGPR.TIPO_TARIFFA <= :p_tariffaA"
        }

        if (filterParam.cognome) {
            filtri << ['p_cognome': filterParam.cognome]
            sqlFiltri += " AND lower(SOGGETTI.COGNOME_RIC) like lower(:p_cognome)"
        } else {
            filterParam.cognome = null
        }

        if (filterParam.nome) {
            filtri << ['p_nome': filterParam.nome]
            sqlFiltri += " AND lower(SOGGETTI.NOME_RIC) like lower(:p_nome)"
        } else {
            filterParam.nome = null
        }

        if (filterParam.nInd) {
            filtri << ['p_nInd': filterParam.nInd]
            sqlFiltri += " AND SOGGETTI.NI = :p_nInd"
        } else {
            filterParam.nInd = null
        }

        if (filterParam.codContribuente) {
            filtri << ['p_codContribuente': filterParam.codContribuente]
            sqlFiltri += " AND CONTRIBUENTI.COD_CONTRIBUENTE = :p_codContribuente"
        } else {
            filterParam.codContribuente = null
        }

        if (filterParam.indirizzo) {
            filtri << ['p_codIndirizzo': filterParam.codIndirizzo]
            sqlFiltri += " AND  OGGE.COD_VIA    + 0 = :p_codIndirizzo"
        } else {
            filterParam.codIndirizzo = 0L
            filterParam.indirizzo = null
        }

        if (filterParam.codiceFiscale) {
            filtri << ['p_codiceFiscale': filterParam.codiceFiscale]
            sqlFiltri += " AND lower(CONTRIBUENTI.COD_FISCALE) like lower(:p_codiceFiscale)"
        } else {
            filterParam.codiceFiscale = null
        }

        if (filterParam.codiceTributo.id != 0L) {
            filtri << ['p_tributo': filterParam.codiceTributo.id]
            sqlFiltri += " and  ogpr.TRIBUTO = :p_tributo"
        }

        if (filterParam.tipoEvento != DEFAULT_TIPO_EVENTO) {
            filtri << ['p_tipoEvento': filterParam.tipoEvento.tipoEventoDenuncia]
            sqlFiltri += " AND PRTR.TIPO_EVENTO = :p_tipoEvento"
        }

        String baseQuery = """

            select translate(soggetti.cognome_nome, '/', ' ') soggnome,
                   ogva.cod_fiscale,
                   contribuenti.ni,
                   decode(contribuenti.cod_controllo,
                          null,
                          to_char(contribuenti.cod_contribuente),
                          contribuenti.cod_contribuente || '-' ||
                          contribuenti.cod_controllo) cod_contr,
                   decode(ogge.cod_via,
                          null,
                          ogge.indirizzo_localita,
                          arvi_ogge.denom_ord) ind_ord,
                   decode(ogge.cod_via,
                          null,
                          ogge.indirizzo_localita,
                          arvi_ogge.denom_uff ||
                          decode(ogge.num_civ, null, '', ', ' || ogge.num_civ) ||
                          decode(ogge.suffisso, null, '', '/' || ogge.suffisso)) indi_ogge,
                   lpad(ogge.num_civ, 6) num_civ,
                   lpad(ogge.suffisso, 5) suffisso,
                   ogpr.consistenza consistenza,
                   ogpr.tipo_tariffa tipo_tariffa,
                   tari.descrizione des_tariffa,
                   ogpr.tributo tributo,
                   ogpr.categoria categoria,
                   cate.descrizione des_categoria,
                   ogpr.oggetto oggetto,
                   ogpr.oggetto_pratica oggetto_pratica,
                   'TARSU' tipo_tributo,
                   nvl(soggetti.stato, 0) stato_sogg,
                   decode(dati_generali.flag_integrazione_gsd,
                          'S',
                          decode(soggetti.tipo_residente,
                                 0,
                                 decode(soggetti.fascia, 1, 'SI', 3, 'NI', 'NO'),
                                 'NO'),
                          decode(soggetti.tipo_residente, 0, 'SI', 'NO')) residente,
                   anadev.descrizione descrizione_stato,
                   soggetti.data_ult_eve,
                   decode(soggetti.cod_via,
                          null,
                          soggetti.denominazione_via,
                          arvi_sogg.denom_uff) indirizzo_res,
                   soggetti.num_civ ||
                   decode(soggetti.suffisso, null, '', '/' || soggetti.suffisso) num_civico_res,
                   lpad(soggetti.cap, 5, '0') cap_res,
                   comu.denominazione comune_res,
                   decode(soggetti.fascia,
                          2,
                          decode(soggetti.stato,
                                 50,
                                 '',
                                 decode(lpad(dati_generali.pro_cliente, 3, '0') ||
                                        lpad(dati_generali.com_cliente, 3, '0'),
                                        lpad(soggetti.cod_pro_res, 3, '0') ||
                                        lpad(soggetti.cod_com_res, 3, '0'),
                                        'ERR',
                                        '')),
                          '') verifica_comune_res,
                   f_verifica_cap(soggetti.cod_pro_res,
                                  soggetti.cod_com_res,
                                  soggetti.cap) verifica_cap,
                   translate(sogg_p.cognome_nome, '/', ' ') soggnome_p,
                   decode(ogco.flag_ab_principale,'S','SI','--') flag_ab_principale ,
                   decode(ogco.flag_ab_principale,
                          null,
                          nvl(ogpr.numero_familiari, cosu.numero_familiari),
                          f_ultimo_faso(contribuenti.ni, tari.anno)) numero_familiari,
                   decode(cate.flag_domestica,'S','SI','--') flag_domestica,
                   ogge.estremi_catasto,
                   ogva.dal,
                   ogva.al,
                   upper(replace(SOGGETTI.COGNOME, ' ', '')) cognome,
                   upper(replace(SOGGETTI.NOME, ' ', '')) nome,
                   tari.anno,
                   1 pr_data,
                   1 clnumero,
                   ogge.sezione,
                   ogge.foglio,
                   ogge.numero,
                   ogge.subalterno,
                   ogge.categoria_catasto,
                   ogva.tipo_occupazione,
                   ogpr.note
              from tariffe               tari,
                   tipi_tributo          titr,
                   codici_tributo        cotr,
                   pratiche_tributo      prtr,
                   oggetti_pratica       ogpr,
                   oggetti_contribuente  ogco,
                   oggetti_validita      ogva,
                   soggetti,
                   contribuenti,
                   archivio_vie          arvi_ogge,
                   oggetti               ogge,
                   anadev,
                   archivio_vie          arvi_sogg,
                   ad4_comuni            comu,
                   soggetti              sogg_p,
                   componenti_superficie cosu,
                   dati_generali,
                   categorie             cate
             where nvl(to_number(to_char(ogva.dal, 'yyyy')), tari.anno) <= tari.anno
               and nvl(ogva.data,
                       to_date('0101' || lpad(to_char(tari.anno), 4, '0'), 'ddmmyyyy')) <=
                   nvl(ogva.data,
                       to_date('0101' || lpad(to_char(tari.anno), 4, '0'), 'ddmmyyyy'))
                  and not exists
             (select 'x'
                      from pratiche_tributo prtr
                     where prtr.tipo_pratica || '' = 'A'
                       and prtr.anno <= tari.anno
                       and prtr.pratica = ogpr.pratica
                       and (trunc(sysdate) - nvl(prtr.data_notifica, trunc(sysdate)) < 60 and
                           flag_adesione is null or prtr.anno = tari.anno)
                       and prtr.flag_denuncia = 'S')
               and tari.tipo_tariffa = ogpr.tipo_tariffa
               and tari.categoria = ogpr.categoria
               and tari.tributo = ogpr.tributo
               and titr.tipo_tributo = cotr.tipo_tributo
               and cotr.tipo_tributo = ogva.tipo_tributo
               and cotr.tributo = ogpr.tributo
               and ogpr.flag_contenzioso is null
               and ogpr.oggetto_pratica = ogva.oggetto_pratica
               and ogco.oggetto_pratica = ogva.oggetto_pratica
               and ogco.cod_fiscale = ogva.cod_fiscale
               and ogva.tipo_tributo = 'TARSU'
               and prtr.pratica = ogpr.pratica
               and nvl(prtr.stato_accertamento, 'D') = 'D'
               and soggetti.ni = contribuenti.ni
               and contribuenti.cod_fiscale = ogva.cod_fiscale
               and arvi_ogge.cod_via(+) = ogge.cod_via
               and ogge.oggetto(+) = ogpr.oggetto
               and soggetti.stato = anadev.cod_ev(+)
               and arvi_sogg.cod_via(+) = soggetti.cod_via
               and soggetti.cod_com_res = comu.comune(+)
               and soggetti.cod_pro_res = comu.provincia_stato(+)
               and soggetti.ni_presso = sogg_p.ni(+)
               and ogpr.consistenza between cosu.da_consistenza(+) and
                   cosu.a_consistenza(+)
               and cate.categoria(+) = ogpr.categoria
               and cate.tributo(+) = ogpr.tributo
               AND tari.anno = :p_anno
               AND cosu.anno(+) = :p_anno
               and ogva.tipo_occupazione = :p_tipoOccupazione
               """

        String orderBy = ""
        if (filterParam.orderByType == CampiOrdinamento.ALFA) {
            orderBy = """
             ORDER BY upper(replace(SOGGETTI.COGNOME, ' ', '')) ASC,
                      upper(replace(SOGGETTI.NOME, ' ', '')) ASC,
                      CONTRIBUENTI.COD_FISCALE ASC
"""
        } else if (filterParam.orderByType == CampiOrdinamento.CF) {
            orderBy = "ORDER BY CONTRIBUENTI.COD_FISCALE ASC"
        }

        def query = """
            $baseQuery
            $sqlFiltri
            $orderBy
        """

        return [query : query,
                filtri: filtri]

    }


    def getUtenzeTari(def filterParam, int pageSize, int activePage) {

        // properties per la paginazione
        int pageStart = activePage * pageSize

        def result = getQueryPerUtenzeTari(filterParam)

        def query = result.query
        def filtri = result.filtri

        def listaUtenzeTariFromDB = sessionFactory.currentSession.createSQLQuery(query).with {

            setFirstResult(pageStart)
            setMaxResults(pageSize)

            filtri.each {
                k, v ->
                    setParameter(k, v)
            }

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        if (pageSize == Integer.MAX_VALUE) {
            return [lista             : listaUtenzeTariFromDB,
                    totaleUtenze      : 0,
                    totaleContribuenti: 0]
        }

        String queryCount = """
            select count(*) as totale_Utenze, count(distinct cod_fiscale) as totale_Contribuenti from (
                $query
         )
        """

        List totali = sessionFactory.currentSession.createSQLQuery(queryCount).with {

            filtri.each {
                k, v ->
                    setParameter(k, v)
            }

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        return [lista             : listaUtenzeTariFromDB,
                totaleUtenze      : totali[0].totaleUtenze as Integer,
                totaleContribuenti: totali[0].totaleContribuenti as Integer]

    }


}
