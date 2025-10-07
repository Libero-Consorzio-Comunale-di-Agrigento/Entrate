package it.finmatica.tr4.contribuenti

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.*
import it.finmatica.tr4.commons.*
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.dto.pratiche.OggettoContribuenteDTO
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.imposte.ImposteService
import it.finmatica.tr4.pratiche.*
import it.finmatica.tr4.sanzioni.SanzioniService
import it.finmatica.tr4.speseNotifica.SpeseNotificaService
import it.finmatica.tr4.contribuenti.RateazioneService
import it.finmatica.tr4.versamenti.VersamentiService
import it.finmatica.tr4.violazioni.FiltroRicercaViolazioni
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.hibernate.SessionFactory
import org.hibernate.criterion.CriteriaSpecification
import org.hibernate.transform.AliasToEntityMapResultTransformer
import transform.AliasToEntityCamelCaseMapResultTransformer

import java.math.RoundingMode
import java.sql.Date
import java.sql.Timestamp
import java.text.DecimalFormat
import java.text.SimpleDateFormat
import java.util.Date as JavaDate

// Rollback della transazione su Exception indicate risolve #55948
@Transactional(rollbackFor = [RuntimeException.class, Application20999Error.class])
class LiquidazioniAccertamentiService {

    private static final Log log = LogFactory.getLog(this)

    static transactional = false
    def dataSource

    ContribuentiService contribuentiService
    ImposteService imposteService
    RateazioneService rateazioneService
    IntegrazioneDePagService integrazioneDePagService
    VersamentiService versamentiService
    CommonService commonService
    SanzioniService sanzioniService
    SpeseNotificaService speseNotificaService

    TributiSession tributiSession

    SessionFactory sessionFactory

    def springSecurityService

    def tipiPratica = [
            'A': 'Accertamento',
            'D': 'Denuncia',
            'L': 'Liquidazione',
            'I': 'Infrazioni Formali',
            'C': 'Concessione Ute',
            'K': 'Calcolo',
            'T': 'Altro',
            'V': 'Ravvedimento',
            'G': 'Ingiunzione Fiscale',
    ]

    def tipoEmissione = [
            A: 'Acconto',
            S: 'Saldo',
            T: 'Totale',
            X: ''
    ]

    def caricaPratica(Long id) {
        return PraticaTributo.createCriteria().get {
            createAlias("contribuente", "conx", CriteriaSpecification.INNER_JOIN)
            createAlias("conx.soggetto", "sogg", CriteriaSpecification.INNER_JOIN)
            createAlias("tipoStato", "tist", CriteriaSpecification.LEFT_JOIN)
            createAlias("sanzioniPratica", "sapr", CriteriaSpecification.LEFT_JOIN)
            createAlias("iter", "ite", CriteriaSpecification.LEFT_JOIN)

            eq('id', id)
        }.toDTO(["contribuente.soggetto", "tipoStato", "sanzioniPratica", "iter", "iter.stato", "iter.tipoAtto"])
    }

    def getVersato(String codFiscale, short anno, String tipoTributo) {

        def totVersSponte = Versamento.createCriteria().get {
            projections {
                sum("importoVersato")
                groupProperty("contribuente.codFiscale")
                groupProperty("tipoTributo.tipoTributo")
                groupProperty("anno")
            }
            eq("contribuente.codFiscale", codFiscale)
            eq("anno", anno)
            eq("tipoTributo.tipoTributo", tipoTributo)
            isNull("pratica")
        }

        def totVersRavv = Versamento.createCriteria().get {
            createAlias("pratica", "prtr", CriteriaSpecification.INNER_JOIN)
            projections {
                sqlProjection "f_importo_vers_ravv({alias}.cod_fiscale, '${tipoTributo}', {alias}.anno, 'U') as tot", "tot", BIG_DECIMAL
                groupProperty("contribuente.codFiscale")
                groupProperty("tipoTributo.tipoTributo")
                groupProperty("anno")
            }
            eq("contribuente.codFiscale", codFiscale)
            eq("anno", anno)
            eq("tipoTributo.tipoTributo", tipoTributo)
            eq("prtr.tipoPratica", "V")
            geProperty("prtr.data", "dataPagamento")
        }

        return [vers: totVersSponte != null ? totVersSponte[0] : 0, versRavv: totVersRavv != null ? totVersRavv[0] : 0]
    }

    def getVersatoPratica(Long pratica) {

        Double versato

        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_versato_pratica(?)}', [Sql.DECIMAL, pratica]) {
            versato = it as Double
        }

        return versato
    }

    def getVersamentiPratica(Long idPratica) {

        List<VersamentoDTO> lista = Versamento.createCriteria().list {
            createAlias("pratica", "prt", CriteriaSpecification.INNER_JOIN)
            createAlias("fonte", "fonte", CriteriaSpecification.LEFT_JOIN)

            eq("prt.id", idPratica)

            order("dataPagamento", "asc")
        }.toDTO()

        return lista
    }

    def getVersamentiViolazione(Long idPratica) {

        def lista = getVersamentiPratica(idPratica)
        //	lista.each { it.rata = (it.rata == 0 ? null : it.rata) }

        return lista
    }

    def getOggettiLiquidazioneImu(Long idPratica) {

        def parametriQuery = [:]
        parametriQuery.pIdPratica = idPratica

        String sql = "          FROM \
                                    OggettoPratica AS oggPrt \
                                INNER JOIN FETCH\
                                    oggPrt.oggettiContribuente AS oggCtr \
                                LEFT OUTER JOIN FETCH \
                                   oggCtr.oggettiImposta AS oggImp \
                                INNER JOIN FETCH \
                                    oggPrt.oggetto AS ogg \
                                INNER JOIN FETCH \
                                    oggPrt.pratica AS prt \
                                LEFT JOIN FETCH \
                                    ogg.archivioVie AS vie \
                                WHERE \
                                  oggPrt.pratica.id = :pIdPratica and \
                                  oggImp.flagCalcolo is null "

        def lista = OggettoPratica.findAll(sql, parametriQuery)
        def listaDto = []

        def conAliquote = AliquotaOgco.findAllByOggettoContribuenteInList(lista*.oggettiContribuente.flatten())
                .groupBy { it.oggettoContribuente }
                .collect { k, v -> k }
                .toDTO()

        def conDetrazioni = DetrazioneOgco.findAllByOggettoContribuenteInList(lista*.oggettiContribuente.flatten())
                .groupBy { it.oggettoContribuente }
                .collect { k, v -> k }
                .toDTO()

        listaDto = lista.toDTO()

        listaDto.findAll { it.singoloOggettoContribuente in conAliquote }*.oggettiContribuente.flatten()*.oggettiImposta.flatten()*.presentiAliquote = true
        listaDto.findAll { it.singoloOggettoContribuente in conDetrazioni }*.oggettiContribuente.flatten()*.oggettiImposta.flatten()*.presentiDetrazioni = true

        listaDto.sort { ogpr1, ogpr2 ->
            ogpr1.numOrdine <=> ogpr2.numOrdine ?:
                    ogpr1.categoriaCatasto?.categoriaCatasto <=> ogpr2.categoriaCatasto?.categoriaCatasto ?:
                            ogpr1.oggetto.categoriaCatasto?.categoriaCatasto <=> ogpr2.oggetto.categoriaCatasto?.categoriaCatasto ?:
                                    ogpr1.oggetto.id <=> ogpr2.oggetto.id
        }

        return listaDto
    }

    def getDettagliPraticaDaOggPr(Long oggPrId) {

        def filtri = [:]

        filtri << ['oggPrId': oggPrId]

        String sql = """
			    SELECT PRTR.PRATICA,
			           PRTR.TIPO_PRATICA,
			           PRTR.ANNO,
			           PRTR.NUMERO,
			           PRTR.TIPO_TRIBUTO
			      FROM PRATICHE_TRIBUTO PRTR,
					   OGGETTI_PRATICA OGPR
			     WHERE PRTR.PRATICA = OGPR.PRATICA
			       AND OGPR.OGGETTO_PRATICA = :oggPrId
		"""

        def results = eseguiQuery(sql, filtri, null, true)

        def dettagli = [id: null]

        results.each {

            dettagli.id = it['PRATICA'] as Long
            dettagli.tipoTributo = it['TIPO_TRIBUTO'] as String
            dettagli.anno = it['ANNO'] as Short
            dettagli.numeroPratica = it['NUMERO'] as String
            dettagli.tipoPratica = it['TIPO_PRATICA'] as String
        }

        return dettagli
    }

    def getNumPraticheDaOggPrRif(String tipoTributo, def tipiPratica, Long oggPrId) {

        def filtri = [:]

        filtri << ['tipoTributo': tipoTributo]
        filtri << ['oggPrId': oggPrId]

        String filtroTipiPratica = "'" + tipiPratica?.join("','") + "'"

        String sql = """
				SELECT COUNT(*) AS CONTEGGIO
				  FROM PRATICHE_TRIBUTO PRTR,
				 	   OGGETTI_PRATICA OGPR,
					   OGGETTI_CONTRIBUENTE OGCO
			    WHERE PRTR.PRATICA = OGPR.PRATICA
				  AND OGCO.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA
		 		  AND OGCO.COD_FISCALE = PRTR.COD_FISCALE
				  AND PRTR.TIPO_PRATICA in (${filtroTipiPratica})
				  AND PRTR.TIPO_TRIBUTO = :tipoTributo
				  AND OGPR.OGGETTO_PRATICA_RIF = :oggPrId
		"""

        def results = eseguiQuery(sql, filtri, null, true)

        Long conteggio = 0

        results.each {

            conteggio = it['CONTEGGIO'] as Long
        }

        return conteggio
    }

    def getOggettiAccertamentoManualeTari(Long idPratica) {

        def lista = []
        def parametriQuery = [:]
        parametriQuery.pIdPratica = idPratica

        String sql = """
				SELECT
					oggPrt.oggetto.id,
					oggPrt.tipoOggetto.tipoOggetto,	
					vie.denomUff,
					ogg.indirizzoLocalita,
					ogg.sezione,
					ogg.foglio,
					ogg.numero,
					ogg.subalterno,
					ogg.zona,
					ogg.protocolloCatasto,
					oggPrt.anno,
					ogg.partita,
					oggPrt.categoriaCatasto.categoriaCatasto,
					oggPrt.consistenza,
					oggPrt.codiceTributo.id,
					cat.categoria||' - '||substr(cat.descrizione, 1, 20) AS cateDescr,
					tariffa.tipoTariffa||' - '||substr(tariffa.descrizione, 1, 30) AS tariDescr,
					oggPrt.tipoOccupazione,	
					oggCtr.percPossesso,
					oggCtr.flagAbPrincipale,
					oggCtr.inizioOccupazione,
					oggCtr.fineOccupazione,
					oggCtr.dataDecorrenza,
					oggCtr.dataCessazione,
					SUM(NVL(oggImp.imposta,0) 
						+ ROUND(NVL(oggImp.addizionaleEca,0),2) 
						+ ROUND(NVL(oggImp.maggiorazioneEca,0),2) 
						+ ROUND(NVL(oggImp.addizionalePro,0),2)
						+ ROUND(NVL(oggImp.iva,0),2)) AS impostaLorda,
					SUM(NVL(oggImp.maggiorazioneTares,0)) AS maggiorazioneTares
				FROM
					OggettoPratica 				 oggPrt
				LEFT JOIN
					oggPrt.tariffa				 tariffa
				LEFT JOIN
					oggPrt.categoria 			 cat
				INNER JOIN
					oggPrt.oggettiContribuente 	 oggCtr
				LEFT JOIN 
					oggCtr.oggettiImposta 		 oggImp
				INNER JOIN
					oggPrt.oggetto 				 ogg
				LEFT JOIN
					ogg.archivioVie 			 vie
				LEFT JOIN
					oggImp.familiariOgim		 fam
				WHERE
					oggPrt.pratica.id = :pIdPratica	AND
					oggImp.flagCalcolo is null 		
				GROUP BY
					oggPrt.oggetto.id,
					oggPrt.tipoOggetto.tipoOggetto,	
					vie.denomUff,
					ogg.indirizzoLocalita,
					ogg.sezione,
					ogg.foglio,
					ogg.numero,
					ogg.subalterno,
					ogg.zona,
					ogg.protocolloCatasto,
					oggPrt.anno,
					ogg.partita,
					oggPrt.categoriaCatasto.categoriaCatasto,
					oggPrt.classeCatasto,
					oggPrt.consistenza,
					oggPrt.codiceTributo.id,
					cat.categoria||' - '||substr(cat.descrizione, 1, 20),
					tariffa.tipoTariffa||' - '||substr(tariffa.descrizione, 1, 30),
					oggPrt.tipoOccupazione,	
					oggCtr.percPossesso,
					oggCtr.flagAbPrincipale,
					oggCtr.inizioOccupazione,
					oggCtr.fineOccupazione,
					oggCtr.dataDecorrenza,
					oggCtr.dataCessazione
				"""
        lista = OggettoPratica.executeQuery(sql, parametriQuery).collect { row ->
            [idOggetto           : row[0]
             , tipoOggetto       : row[1]
             , indirizzo         : row[2]
             , indirizzoLocalita : row[3]
             , sezione           : row[4]
             , foglio            : row[5]
             , numero            : row[6]
             , subalterno        : row[7]
             , zona              : row[8]
             , protocolloCat     : row[9]
             , annoCat           : row[10]
             , partita           : row[11]
             , catCatasto        : row[12]
             , consistenza       : row[13]
             , codiceTributo     : row[14]
             , categoria         : row[15]
             , tipoTariffa       : row[16]
             , occupazione       : row[17]
             , percPossesso      : row[18]
             , flagAbPrincipale  : row[19]
             , inizioOcc         : row[20]
             , fineOcc           : row[21]
             , dataDecorrenza    : row[22]
             , dataCessazione    : row[23]
             , impostaLorda      : row[24]
             , maggiorazioneTares: row[25]
            ]
        }
    }

    def getOggettiAccertamentoAutomaticoTari(Long idPratica) {

        def lista = []
        def parametriQuery = [:]
        parametriQuery.pIdPratica = idPratica

        String sql = """
				SELECT
					oggPrt.oggetto.id,
					oggPrt.tipoOggetto.tipoOggetto,	
					vie.denomUff,
					ogg.indirizzoLocalita,
					ogg.sezione,
					ogg.foglio,
					ogg.numero,
					ogg.subalterno,
					ogg.zona,
					ogg.protocolloCatasto,
					oggPrt.anno,
					ogg.partita,
					oggPrt.categoriaCatasto.categoriaCatasto,
					oggPrt.consistenza,
					oggPrt.codiceTributo.id,
					cat.categoria||' - '||substr(cat.descrizione, 1, 20) AS cateDescr,
					tariffa.tipoTariffa||' - '||substr(tariffa.descrizione, 1, 30) AS tariDescr,
					oggPrt.tipoOccupazione,	
					oggCtr.percPossesso,
					oggCtr.flagAbPrincipale,
					oggCtr.inizioOccupazione,
					oggCtr.fineOccupazione,
					oggCtr.dataDecorrenza,
					oggCtr.dataCessazione,
 					ogg.numCiv,
					ogg.suffisso,
					SUM(oggImp.imposta 
						+ ROUND(oggImp.addizionaleEca,2) 
						+ ROUND(oggImp.maggiorazioneEca,2) 
						+ ROUND(oggImp.addizionalePro,2)
						+ ROUND(oggImp.iva,2)) AS impostaLorda,
					SUM(oggImp.maggiorazioneTares) AS maggiorazioneTares
				FROM
					OggettoPratica 				 oggPrt
				LEFT JOIN
					oggPrt.tariffa				 tariffa
				LEFT JOIN
					oggPrt.categoria 			 cat
				INNER JOIN
					oggPrt.oggettiContribuente 	 oggCtr
				INNER JOIN 
					oggCtr.oggettiImposta 		 oggImp
				INNER JOIN
					oggPrt.oggetto 				 ogg
				LEFT JOIN
					ogg.archivioVie 			 vie
				LEFT JOIN
					oggImp.familiariOgim		 fam
				WHERE
					oggPrt.pratica.id = :pIdPratica	AND
					oggImp.flagCalcolo is null 		
				GROUP BY
					oggPrt.oggetto.id,
					oggPrt.tipoOggetto.tipoOggetto,	
					vie.denomUff,
					ogg.indirizzoLocalita,
					ogg.sezione,
					ogg.foglio,
					ogg.numero,
					ogg.subalterno,
					ogg.zona,
					ogg.protocolloCatasto,
					oggPrt.anno,
					ogg.partita,
					oggPrt.categoriaCatasto.categoriaCatasto,
					oggPrt.classeCatasto,
					oggPrt.consistenza,
					oggPrt.codiceTributo.id,
					cat.categoria||' - '||substr(cat.descrizione, 1, 20),
					tariffa.tipoTariffa||' - '||substr(tariffa.descrizione, 1, 30),
					oggPrt.tipoOccupazione,	
					oggCtr.percPossesso,
					oggCtr.flagAbPrincipale,
					oggCtr.inizioOccupazione,
					oggCtr.fineOccupazione,
					oggCtr.dataDecorrenza,
					oggCtr.dataCessazione,
 					ogg.numCiv,
					ogg.suffisso
		"""

        return OggettoPratica.executeQuery(sql, parametriQuery).collect { row ->
            [idOggetto           : row[0]
             , tipoOggetto       : row[1]
             , indirizzo         : row[2]
             , indirizzoLocalita : row[3]
             , sezione           : row[4]
             , foglio            : row[5]
             , numero            : row[6]
             , subalterno        : row[7]
             , zona              : row[8]
             , protocolloCat     : row[9]
             , annoCat           : row[10]
             , partita           : row[11]
             , catCatasto        : row[12]
             , consistenza       : row[13]
             , codiceTributo     : row[14]
             , categoria         : row[15]
             , tipoTariffa       : row[16]
             , occupazione       : row[17]
             , percPossesso      : row[18]
             , flagAbPrincipale  : row[19]
             , inizioOcc         : row[20]
             , fineOcc           : row[21]
             , dataDecorrenza    : row[22]
             , dataCessazione    : row[23]
             , numCiv            : row[24]
             , suffisso          : row[25]
             , indirizzoCompleto : (row[2] == null ? row[3] : row[2]) + " " + (row[24] == null ? "" : ", " + row[24]) + (row[25] == null ? "" : "/" + row[25]) != "null " ?
                    (row[2] == null ? row[3] : row[2]) + " " + (row[24] == null ? "" : ", " + row[24]) + (row[25] == null ? "" : "/" + row[25]) : " "
             , impostaLorda      : row[26]
             , maggiorazioneTares: row[27]
            ]
        }
    }

    def getOggettiAccertamentoAutomaticoTribMin(Long idPratica) {

        def lista = []
        def parametriQuery = [:]
        parametriQuery.pIdPratica = idPratica

        String sql = """
				SELECT
					oggPrt.oggetto.id,
					oggPrt.tipoOggetto.tipoOggetto,	
					vie.denomUff,
					ogg.indirizzoLocalita,
					ogg.sezione,
					ogg.foglio,
					ogg.numero,
					ogg.subalterno,
					ogg.zona,
					ogg.protocolloCatasto,
					oggPrt.anno,
					ogg.partita,
					oggPrt.categoriaCatasto.categoriaCatasto,
					oggPrt.consistenza,
					oggPrt.codiceTributo.id,
					cat.categoria||' - '||substr(cat.descrizione, 1, 20) AS cateDescr,
					tariffa.tipoTariffa||' - '||substr(tariffa.descrizione, 1, 30) AS tariDescr,
					oggPrt.tipoOccupazione,	
					oggCtr.percPossesso,
					oggCtr.flagAbPrincipale,
					oggCtr.inizioOccupazione,
					oggCtr.fineOccupazione,
					oggCtr.dataDecorrenza,
					oggCtr.dataCessazione,
 					ogg.numCiv,
					ogg.suffisso,
					SUM(oggImp.imposta + ROUND(oggImp.iva,2)) AS impostaLorda
				FROM
					OggettoPratica 				 oggPrt
				LEFT JOIN
					oggPrt.tariffa				 tariffa
				LEFT JOIN
					oggPrt.categoria 			 cat
				INNER JOIN
					oggPrt.oggettiContribuente 	 oggCtr
				INNER JOIN 
					oggCtr.oggettiImposta 		 oggImp
				INNER JOIN
					oggPrt.oggetto 				 ogg
				LEFT JOIN
					ogg.archivioVie 			 vie
				LEFT JOIN
					oggImp.familiariOgim		 fam
				WHERE
					oggPrt.pratica.id = :pIdPratica	AND
					oggImp.flagCalcolo is null 		
				GROUP BY
					oggPrt.oggetto.id,
					oggPrt.tipoOggetto.tipoOggetto,	
					vie.denomUff,
					ogg.indirizzoLocalita,
					ogg.sezione,
					ogg.foglio,
					ogg.numero,
					ogg.subalterno,
					ogg.zona,
					ogg.protocolloCatasto,
					oggPrt.anno,
					ogg.partita,
					oggPrt.categoriaCatasto.categoriaCatasto,
					oggPrt.classeCatasto,
					oggPrt.consistenza,
					oggPrt.codiceTributo.id,
					cat.categoria||' - '||substr(cat.descrizione, 1, 20),
					tariffa.tipoTariffa||' - '||substr(tariffa.descrizione, 1, 30),
					oggPrt.tipoOccupazione,	
					oggCtr.percPossesso,
					oggCtr.flagAbPrincipale,
					oggCtr.inizioOccupazione,
					oggCtr.fineOccupazione,
					oggCtr.dataDecorrenza,
					oggCtr.dataCessazione,
 					ogg.numCiv,
					ogg.suffisso
				"""

        lista = OggettoPratica.executeQuery(sql, parametriQuery).collect { row ->
            [idOggetto          : row[0]
             , tipoOggetto      : row[1]
             , indirizzo        : row[2]
             , indirizzoLocalita: row[3]
             , sezione          : row[4]
             , foglio           : row[5]
             , numero           : row[6]
             , subalterno       : row[7]
             , zona             : row[8]
             , protocolloCat    : row[9]
             , annoCat          : row[10]
             , partita          : row[11]
             , catCatasto       : row[12]
             , consistenza      : row[13]
             , codiceTributo    : row[14]
             , categoria        : row[15]
             , tipoTariffa      : row[16]
             , occupazione      : row[17]
             , percPossesso     : row[18]
             , flagAbPrincipale : row[19]
             , inizioOcc        : row[20]
             , fineOcc          : row[21]
             , dataDecorrenza   : row[22]
             , dataCessazione   : row[23]
             , numCiv           : row[24]
             , suffisso         : row[25]
             , indirizzoCompleto: (row[2] == null ? row[3] : row[2]) + " " + (row[24] == null ? "" : ", " + row[24]) + (row[25] == null ? "" : "/" + row[25]) != "null " ?
                    (row[2] == null ? row[3] : row[2]) + " " + (row[24] == null ? "" : ", " + row[24]) + (row[25] == null ? "" : "/" + row[25]) : " "
             , impostaLorda     : row[26]
            ]
        }
    }

    def getOggettiAccertamentiManualiTotale(Long idPratica, String codFiscale, short anno) {
        return OggettoPratica.createCriteria().list {
            createAlias("oggetto", "ogg", CriteriaSpecification.INNER_JOIN)
            createAlias("ogg.archivioVie", "vie", CriteriaSpecification.LEFT_JOIN)
            createAlias("pratica", "prt", CriteriaSpecification.INNER_JOIN)

            eq("prt.id", idPratica)
            eq("prt.contribuente.codFiscale", codFiscale)

            order("ogg.id", "asc")
            order("ogg.protocolloCatasto", "asc")
            order("ogg.sezione", "asc")
            order("ogg.foglio", "asc")
            order("ogg.numero", "asc")
            order("ogg.subalterno", "asc")
        }.toDTO()
    }

    def getDichiaratoAccertamentoManualeTotaleImu(Long idPratica, String codFiscale, short anno, long tipoOggetto) {
        def listaDichiarati = []
        OggettoPratica oggettoPraticaDichiarato = getOggettoPraticaDichiarato(idPratica)
        if (oggettoPraticaDichiarato?.oggettoPraticaRif?.id) {
            def lista = OggettoPratica.createCriteria().list {
                createAlias("oggetto", "ogg", CriteriaSpecification.INNER_JOIN)
                createAlias("pratica", "prtTri", CriteriaSpecification.INNER_JOIN)
                createAlias("oggettiContribuente", "oggContr", CriteriaSpecification.INNER_JOIN)
                createAlias("oggContr.oggettiImposta", "oggImp", CriteriaSpecification.LEFT_JOIN)

                eq("oggImp.anno", anno)
                eq("oggContr.contribuente.codFiscale", codFiscale)
                eq("id", oggettoPraticaDichiarato?.oggettoPraticaRif?.id)
            }

            def listaDic = [:]
            for (oggettoPrt in lista) {

                listaDic.tipoOggetto = oggettoPrt.tipoOggetto ?: oggettoPrt.oggetto.tipoOggetto

                BigDecimal valore
                //Connection conn = DataSourceUtils.getConnection(dataSource)
                Sql sql = new Sql(dataSource)
                sql.call('{? = call f_valore(?, ?, ?, ?, ?, ?, ?)}'
                        , [Sql.DECIMAL, oggettoPraticaDichiarato.oggettoPraticaRif.valore
                           , tipoOggetto
                           , oggettoPrt.pratica.anno
                           , anno
                           , oggettoPraticaDichiarato.oggettoPraticaRif?.categoriaCatasto?.categoriaCatasto
                           , oggettoPrt.pratica.tipoPratica
                           , oggettoPraticaDichiarato.oggettoPraticaRif.flagValoreRivalutato]) { valore = it }

                listaDic.valore = valore
                listaDic.flagRivalutato = ((anno - 1996) > 0) ? 'S' : null
                listaDic.percPossesso = oggettoPrt.oggettiContribuente.percPossesso
                listaDic.mesiPossesso = ((oggettoPrt.pratica.anno == anno) ? oggettoPrt.oggettiContribuente[0].mesiPossesso : 12)
                listaDic.primoSem = ((oggettoPrt.pratica.anno == anno) ? oggettoPrt.oggettiContribuente[0].mesiPossesso1sem : 6)
                listaDic.mesiEsclusione = ((oggettoPrt.pratica.anno == anno) ?
                        ((oggettoPrt.oggettiContribuente.flagEsclusione == 'S') ?
                                ((oggettoPrt.oggettiContribuente.mesiEsclusione) ?: ((oggettoPrt.oggettiContribuente.mesiPossesso) ?: 12)) :
                                (oggettoPrt.oggettiContribuente.mesiEsclusione)) :
                        ((oggettoPrt.oggettiContribuente.flagEsclusione == 'S') ? 12 : null))

                listaDic.mesiRiduzione = ((oggettoPrt.pratica.anno == anno) ?
                        ((oggettoPrt.oggettiContribuente.flagRiduzione == 'S') ?
                                ((oggettoPrt.oggettiContribuente.mesiRiduzione) ?: ((oggettoPrt.oggettiContribuente.mesiPossesso) ?: 12)) :
                                (oggettoPrt.oggettiContribuente.mesiRiduzione)) :
                        ((oggettoPrt.oggettiContribuente.flagRiduzione == 'S') ? 12 : null))

                def maggDet = getMaggioreDet(anno, 'ICI', codFiscale)

                listaDic.detrazione = ((oggettoPrt.pratica.anno == anno) ?
                        (oggettoPrt.oggettiContribuente.detrazione) :
                        ((oggettoPrt.oggettiContribuente.flagAbPrincipale) ?
                                (maggDet ? maggDet : oggettoPrt.oggettiContribuente.detrazione) :
                                (oggettoPrt.oggettiContribuente.detrazione)))

                listaDic.categoriaCatasto = oggettoPrt.categoriaCatasto
                listaDic.classeCatasto = oggettoPrt.classeCatasto
                listaDic.imposta = oggettoPrt.oggettiContribuente[0]?.oggettiImposta[0]?.imposta
                listaDic.data = oggettoPrt.pratica.data

                listaDichiarati << listaDic
            }
        }
        return listaDichiarati
    }

    def getOggettoPraticaDichiarato(Long idPratica) {
        def oggPrt = OggettoPratica.createCriteria().list { eq("pratica.id", idPratica) }

        return (oggPrt.size() > 0) ? oggPrt[0] : null
    }

    //CALCOLO MAGGIORE DETRAZIONE
    def getMaggioreDet(short anno, String tipoTributo, String codFiscale) {
        def magg = MaggioreDetrazione.createCriteria().list {
            projections { property("detrazione") }
            eq("anno", anno)
            eq("tipoTributo.tipoTributo", tipoTributo)
            eq("contribuente.codFiscale", codFiscale)
        }
    }

    def getLiquidatoAccertamentoManualeTotaleImu(Long idPratica, String codFiscale, short anno) {

        OggettoPratica oggettoPraticaLiquidato = getOggettoPraticaDichiarato(idPratica)
        def lista
        if (oggettoPraticaLiquidato?.oggettoPraticaRif?.id) {
            lista = OggettoPratica.createCriteria().list {
                createAlias("oggetto", "ogg", CriteriaSpecification.INNER_JOIN)
                createAlias("pratica", "prt", CriteriaSpecification.INNER_JOIN)
                createAlias("oggettiContribuente", "oggCtr", CriteriaSpecification.INNER_JOIN)
                createAlias("oggCtr.oggettiImposta", "oggImp", CriteriaSpecification.LEFT_JOIN)
                projections {
                    groupProperty("tipoOggetto")                //0
                    groupProperty("ogg.tipoOggetto")            //1
                    groupProperty("valore")                        //2
                    groupProperty("flagValoreRivalutato")        //3
                    groupProperty("oggCtr.percPossesso")        //4
                    groupProperty("oggCtr.mesiPossesso")        //5
                    groupProperty("oggCtr.mesiPossesso1sem")    //6
                    groupProperty("oggCtr.mesiEsclusione")        //7
                    groupProperty("oggCtr.mesiRiduzione")        //8
                    groupProperty("oggCtr.detrazione")            //9
                    groupProperty("categoriaCatasto")            //10
                    groupProperty("classeCatasto")                //11
                    groupProperty("oggImp.imposta")                //12
                    groupProperty("prt.data")                    //13
                }
                eq("prt.tipoPratica", 'L')
                eq("prt.anno", anno)
                eq("oggCtr.contribuente.codFiscale", codFiscale)
                isNotNull("prt.dataNotifica")
                eq("oggettoPraticaRif.id", oggettoPraticaLiquidato?.oggettoPraticaRif?.id)
                eq("prt.tipoEvento", TipoEventoDenuncia.R)
                or {
                    isNull("oggImp.anno")
                    eq("oggImp.anno", anno)
                }
            }

            if (lista.size == 0) {
                lista = OggettoPratica.createCriteria().list {
                    createAlias("oggetto", "ogg", CriteriaSpecification.INNER_JOIN)
                    createAlias("pratica", "prt", CriteriaSpecification.INNER_JOIN)
                    createAlias("oggettiContribuente", "oggCtr", CriteriaSpecification.INNER_JOIN)
                    createAlias("oggCtr.oggettiImposta", "oggImp", CriteriaSpecification.LEFT_JOIN)
                    projections {
                        groupProperty("tipoOggetto")                //0
                        groupProperty("ogg.tipoOggetto")            //1
                        groupProperty("valore")                        //2
                        groupProperty("flagValoreRivalutato")        //3
                        groupProperty("oggCtr.percPossesso")        //4
                        groupProperty("oggCtr.mesiPossesso")        //5
                        groupProperty("oggCtr.mesiPossesso1sem")    //6
                        groupProperty("oggCtr.mesiEsclusione")        //7
                        groupProperty("oggCtr.mesiRiduzione")        //8
                        groupProperty("oggCtr.detrazione")            //9
                        groupProperty("categoriaCatasto")            //10
                        groupProperty("classeCatasto")                //11
                        groupProperty("oggImp.imposta")                //12
                        groupProperty("prt.data")                    //13
                    }

                    eq("prt.tipoPratica", 'L')
                    eq("prt.anno", anno)
                    eq("oggCtr.contribuente.codFiscale", codFiscale)
                    isNotNull("prt.dataNotifica")
                    eq("oggettoPraticaRif.id", oggettoPraticaLiquidato?.oggettoPraticaRif?.id)
                    eq("prt.tipoEvento", TipoEventoDenuncia.U)
                    or
                            {
                                isNull("oggImp.anno")
                                eq("oggImp.anno", anno)
                            }
                }
            }

            lista.collect { row ->
                [tipoOggettoOgpr       : row[0]
                 , tipoOggettoOgg      : row[1]
                 , valore              : row[2]
                 , flagValoreRivalutato: row[3]
                 , percPossesso        : row[4]
                 , mesiPossesso        : row[5]
                 , primoSem            : row[6]
                 , mesiEsclusione      : row[7]
                 , mesiRiduzione       : row[8]
                 , detrazione          : row[9]
                 , categoriaCatasto    : row[10]
                 , classeCatasto       : row[11]
                 , imposta             : row[12]
                 , data                : row[13]
                ]
            }
        }
    }

    def getAccertatoAccertamentoManualeTotaleImu(Long idPratica, String codFiscale, short anno, String accertamento) {
        def lista = OggettoPratica.createCriteria().list {
            createAlias("oggetto", "ogg", CriteriaSpecification.INNER_JOIN)
            createAlias("pratica", "prt", CriteriaSpecification.INNER_JOIN)
            createAlias("oggettiContribuente", "oggCtr", CriteriaSpecification.INNER_JOIN)
            createAlias("oggCtr.oggettiImposta", "oggImp", CriteriaSpecification.LEFT_JOIN)

            or {
                eq("oggImp.anno", anno)
                isNull("oggImp.anno")
            }
            eq("oggCtr.contribuente.codFiscale", codFiscale)
            eq("prt.id", idPratica)
            eq("prt.anno", anno)
        }

        List listaAccertati = []
        def listaAcc = [:]
        for (oggettoPrt in lista) {
            listaAcc.tipoOggetto = oggettoPrt.tipoOggetto
            BigDecimal valore
            /* In base al tipo di accertamento il VALORE viene calcolato in maniera differente:
             se l'accertamento è di tipo MANUALE viene preso il valore di oggettoPratica
             se l'accertamento è di tipo TOTALE il VALORE viene calcolato in base
             al flagValoreRivalutato: se il flag vale 'S' viene preso il valore di oggettoPratica
             altrimenti va chiamata la funzione f_valore per ricalcolarlo */

            if (accertamento == 'T') {
                if (oggettoPrt.flagValoreRivalutato == 'S') {
                    valore = oggettoPrt.valore
                } else {

                    //Connection conn = DataSourceUtils.getConnection(dataSource)
                    Sql sql = new Sql(dataSource)
                    sql.call('{? = call f_valore(?, ?, ?, ?, ?, ?, ?)}'
                            , [Sql.DECIMAL, oggettoPrt.valore
                               , oggettoPrt.tipoOggetto.tipoOggetto  //passare il tipoOggetto di oggettoPratica
                               , oggettoPrt.pratica.anno
                               , anno
                               , oggettoPrt.categoriaCatasto?.categoriaCatasto
                               , oggettoPrt.pratica.tipoPratica
                               , oggettoPrt.flagValoreRivalutato ? "S" : null]) { valore = it }
                }
            } else if (accertamento == 'M') {
                valore = oggettoPrt.valore
            }
            listaAcc.valore = valore

            listaAcc.flagRivalutato = oggettoPrt.flagValoreRivalutato
            listaAcc.percPossesso = oggettoPrt.oggettiContribuente[0].percPossesso
            listaAcc.mesiPossesso = oggettoPrt.oggettiContribuente[0].mesiPossesso
            listaAcc.primoSem = oggettoPrt.oggettiContribuente[0].mesiPossesso1sem
            listaAcc.mesiEsclusione = oggettoPrt.oggettiContribuente[0].mesiEsclusione
            listaAcc.mesiRiduzione = oggettoPrt.oggettiContribuente[0].mesiRiduzione
            listaAcc.detrazione = oggettoPrt.oggettiContribuente[0].detrazione
            listaAcc.categoriaCatasto = oggettoPrt.categoriaCatasto
            listaAcc.classeCatasto = oggettoPrt.classeCatasto
            listaAcc.imposta = oggettoPrt.oggettiContribuente[0].oggettiImposta[0]?.imposta
            listaAcc.data = oggettoPrt.pratica.data
            listaAcc.tipoAliquota = oggettoPrt.oggettiContribuente[0].oggettiImposta[0]?.tipoAliquota

            if (oggettoPrt.indirizzoOcc) {
                listaAcc.tipoAliquotaAP = TipoAliquota.createCriteria().get {
                    eq('tipoTributo.tipoTributo', oggettoPrt.pratica.tipoTributo.tipoTributo)
                    eq('tipoAliquota', new Integer(oggettoPrt.indirizzoOcc.substring(0, 2)))
                }
                listaAcc.aliquotaAP = (new BigDecimal(oggettoPrt.indirizzoOcc.substring(2, 8)) / 100)
            }

            listaAcc.detrazioneAP = oggettoPrt.oggettiContribuente[0].oggettiImposta[0]?.detrazionePrec
            listaAcc.aliquota = oggettoPrt.oggettiContribuente[0].oggettiImposta[0]?.aliquota
            listaAcc.importoVersato = oggettoPrt.oggettiContribuente[0].oggettiImposta[0]?.importoVersato
            listaAcc.impostaAcconto = oggettoPrt.oggettiContribuente[0].oggettiImposta[0]?.impostaAcconto
            listaAcc.flagPossesso = oggettoPrt.oggettiContribuente[0].flagPossesso
            listaAcc.flagEsclusione = oggettoPrt.oggettiContribuente[0].flagEsclusione
            listaAcc.flagRiduzione = oggettoPrt.oggettiContribuente[0].flagRiduzione
            listaAcc.flagAbPrincipale = oggettoPrt.oggettiContribuente[0].flagAbPrincipale

            listaAccertati << listaAcc
        }
        return listaAccertati
    }

    def getDichiaratoAccertamentoManualeTari(Long idPratica, String codFiscale, short anno) {

        List listaDichiarati = []

        OggettoPratica oggettoPraticaDichiarato = getOggettoPraticaDichiarato(idPratica)

        //se l'oggettoPraticaRif non è valorizzato il Dichiarato non va visualizzato
        if (oggettoPraticaDichiarato?.oggettoPraticaRif?.id) {

            BigDecimal valoreImpostaNetta
            BigDecimal valoreImpostaLorda
            //Connection conn = DataSourceUtils.getConnection(dataSource)
            Sql sql = new Sql(dataSource)
            sql.call('{? = call f_get_imposta_netta_per_ogpr(?, ?, ?)}'
                    , [Sql.DECIMAL, oggettoPraticaDichiarato.oggettoPraticaRif.id
                       , anno
                       , codFiscale]) { valoreImpostaNetta = it }
            sql.call('{? = call f_get_imposta_lorda_per_ogpr(?, ?, ?)}'
                    , [Sql.DECIMAL, oggettoPraticaDichiarato.oggettoPraticaRif.id
                       , anno
                       , codFiscale]) { valoreImpostaLorda = it }

            def lista = OggettoPratica.createCriteria().list {
                createAlias("categoria", "cat", CriteriaSpecification.LEFT_JOIN)
                createAlias("tariffa", "tar", CriteriaSpecification.LEFT_JOIN)
                createAlias("oggettiContribuente", "oggCtr", CriteriaSpecification.INNER_JOIN)
                createAlias("oggCtr.oggettiImposta", "oggImp", CriteriaSpecification.LEFT_JOIN)
                createAlias("oggImp.ruolo", "ruolo", CriteriaSpecification.INNER_JOIN)
                createAlias("pratica", "prt", CriteriaSpecification.INNER_JOIN)
                createAlias("prt.tipoTributo", "tipoTri", CriteriaSpecification.INNER_JOIN)
                createAlias("tipoTri.codiciTributo", "codTri", CriteriaSpecification.INNER_JOIN)

                projections {
                    groupProperty("consistenza")
                    groupProperty("oggCtr.inizioOccupazione")
                    groupProperty("oggCtr.dataDecorrenza")
                    groupProperty("oggCtr.fineOccupazione")
                    groupProperty("oggCtr.dataCessazione")
                    groupProperty("prt.data")
                    groupProperty("codiceTributo.id")
                    groupProperty("cat.categoria")
                    groupProperty("cat.descrizione")
                    groupProperty("tar.tipoTariffa")
                    groupProperty("tar.descrizione")
                    groupProperty("oggCtr.percPossesso")
                    groupProperty("tipoOccupazione")
                    groupProperty("oggCtr.flagAbPrincipale")
                    groupProperty("numeroFamiliari")
                }

                or {
                    isNull("oggImp.anno")
                    eq("oggImp.anno", anno)
                }
                eq("oggCtr.contribuente.codFiscale", codFiscale)
                eq("id", oggettoPraticaDichiarato.oggettoPraticaRif.id)
                isNotNull("oggImp.ruolo")
                isNotNull("ruolo.invioConsorzio")
            }

            def listaDic = [:]
            for (oggettoPrt in lista) {

                listaDic.superficie = oggettoPrt[0]
                listaDic.inizioOcc = oggettoPrt[1]
                listaDic.decorrenza = oggettoPrt[2]
                listaDic.fineOcc = oggettoPrt[3]
                listaDic.cessazione = oggettoPrt[4]
                listaDic.imposta = valoreImpostaNetta
                listaDic.impostaLorda = valoreImpostaLorda
                listaDic.data = oggettoPrt[5]
                listaDic.codTributo = oggettoPrt[6]
                listaDic.categoria = oggettoPrt[7] + " - " + oggettoPrt[8]
                listaDic.tariffa = oggettoPrt[9] + " - " + oggettoPrt[10]
                listaDic.percPossesso = oggettoPrt[11]
                listaDic.occupazione = oggettoPrt[12]
                listaDic.flagAbPrincipale = oggettoPrt[13]
                listaDic.numFamiliari = oggettoPrt[14]

                listaDichiarati << listaDic
            }
        }
        return listaDichiarati
    }

    def getAccertatoAccertamentoManualeTari(Long idPratica, String codFiscale, short anno) {
        def listaAcc = []
        def parametriQuery = [:]
        parametriQuery.pIdPratica = idPratica
        parametriQuery.pCodFiscale = codFiscale
        parametriQuery.pAnno = anno

        String sql = """
              			SELECT
						  oggPrtAcc.consistenza,
						  oggCtr.inizioOccupazione,
						  oggCtr.dataDecorrenza,
						  oggCtr.fineOccupazione,
						  oggCtr.dataCessazione,
						  decode(decode(ruolo.id,null,coalesce(cata.flagLordo,'N'),coalesce(ruolo.importoLordo,'N'))
							,'S',decode(codTri.flagRuolo
					  		,'S',round(oggImpAcc.imposta * nvl(cata.addizionaleEca,0) / 100,2)    +
						   	round(oggImpAcc.imposta * nvl(cata.maggiorazioneEca,0) / 100,2)  +
						   	round(oggImpAcc.imposta * nvl(cata.addizionalePro,0) / 100,2)    +
						  	round(oggImpAcc.imposta * nvl(cata.aliquota, 0) / 100,2),0),0) + oggImpAcc.imposta as imposta,
		 				  oggPrtAcc.codiceTributo.id,
						  oggPrtAcc.categoria.categoria,
						  oggPrtAcc.categoria.descrizione,
						  oggPrtAcc.tipoTariffa,
						  oggPrtAcc.tariffa.descrizione,
						  oggCtr.flagAbPrincipale,
						  oggPrtAcc.tipoOccupazione,
						  oggCtr.percPossesso,
						  oggPrtAcc.numeroFamiliari			
              			FROM
							CaricoTarsu as cata,
							PraticaTributo as prt
						INNER JOIN
							prt.oggettiPratica as oggPrtAcc
						INNER JOIN
							oggPrtAcc.codiceTributo as codTri
						LEFT JOIN
							oggPrtAcc.oggettoPraticaRifAp as oggPrtRif
						LEFT JOIN
							oggPrtAcc.oggettiContribuente as oggCtr
						INNER JOIN
							oggCtr.oggettiImposta as oggImpAcc
						LEFT JOIN
							oggCtr.oggettiImposta as oggImpDic
						LEFT JOIN
							oggImpDic.ruolo as ruolo
			  			WHERE
							cata.anno = :pAnno 		
						AND oggImpAcc.anno = :pAnno 
						AND oggImpDic.anno = :pAnno 
						AND oggCtr.contribuente.codFiscale = :pCodFiscale 
						AND prt.id = :pIdPratica 
						
					"""
        listaAcc = PraticaTributo.executeQuery(sql, parametriQuery).collect { row ->
            [
                    superficie        : row[0]
                    , inizioOcc       : row[1]
                    , decorrenza      : row[2]
                    , fineOcc         : row[3]
                    , cessazione      : row[4]
                    , imposta         : row[5]
                    , codTributo      : row[6]
                    , categoria       : row[7] + " " + row[8]
                    , tariffa         : row[9] + " " + row[10]
                    , flagAbPrincipale: row[11]
                    , occupazione     : row[12]
                    , percPossesso    : row[13]
                    , numFamiliari    : row[14]
            ]
        }
    }

    def getOggettiAccManTotTari(Long idPratica, short anno) {

        def filtri = [:]

        filtri << ['p_pratica': idPratica]
        filtri << ['p_anno': anno]

        String sql = """
				SELECT
					OGPR.OGGETTO_PRATICA,
					OGPR.TIPO_OGGETTO,
					OGGE.NUM_CIV,
					OGGE.SUFFISSO,
					OGGE.SCALA,
					OGGE.PIANO,
					OGGE.INTERNO,
					OGGE.COD_VIA,
					OGCR.PERC_POSSESSO,
					OGPR.PRATICA,
					OGGE.ANNO_CATASTO,
					OGGE.SEZIONE,
					OGGE.FOGLIO,
					OGGE.NUMERO,
					OGGE.SUBALTERNO,
					OGGE.ZONA,
					OGGE.OGGETTO,
					decode(OGGE.COD_VIA,NULL,INDIRIZZO_LOCALITA,DENOM_UFF||
												decode(NUM_CIV,NULL,'',','||NUM_CIV )||
												decode(SUFFISSO,NULL,'','/'||SUFFISSO )||
												decode(INTERNO,NULL,'',' INT. '||INTERNO )) INDIRIZZO_OGG,
					lpad(OGGE.PARTITA,8) PARTITA,
					lpad(OGGE.PROTOCOLLO_CATASTO,6) PROTOCOLLO_CATASTO,
					OGPR.CATEGORIA,
					OGPR.CONSISTENZA,
					OGPR.TIPO_OCCUPAZIONE,
					OGPR.CATEGORIA,
					OGPR.TIPO_TARIFFA,
					OGCR.INIZIO_OCCUPAZIONE,
					OGCR.FINE_OCCUPAZIONE,
					OGCR.DATA_DECORRENZA,
					OGCR.DATA_CESSAZIONE,
					OGCR.FLAG_AB_PRINCIPALE,
					nvl(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO) CATEGORIA_CATASTO,
					nvl(OGPR.CLASSE_CATASTO,OGGE.CLASSE_CATASTO) CLASSE_CATASTO,
					OGPR.TRIBUTO,
					TARI.TIPO_TARIFFA||' - '||substr(TARI.DESCRIZIONE,1,30) TARI_DESCR,
					CATE.CATEGORIA||' - '||substr(CATE.DESCRIZIONE,1,20) CATE_DESCR,
					sum(OGIM.IMPOSTA
					+ round(OGIM.addizionale_eca,2)
					+ round(OGIM.maggiorazione_eca,2)
					+ round(OGIM.addizionale_pro,2)
					+ round(OGIM.iva,2)) IMPOSTA_LORDA,
					sum(OGIM.MAGGIORAZIONE_TARES) MAGGIORAZIONE_TARES,
					decode(CATE.FLAG_DOMESTICA,'S',FAOG.NUMERO_FAMILIARI,NULL) NUMERO_FAMILIARI,
					decode(CATE.FLAG_DOMESTICA,'S',FAOG.DAL,NULL) FAOG_DAL,
					decode(CATE.FLAG_DOMESTICA,'S',FAOG.AL,NULL) FAOG_AL,
					CATE.FLAG_DOMESTICA
				FROM
					OGGETTI_CONTRIBUENTE OGCR,
					OGGETTI_PRATICA OGPR,
					OGGETTI OGGE,
					ARCHIVIO_VIE AVIE,
					OGGETTI_IMPOSTA OGIM,
					TARIFFE TARI,
					CATEGORIE CATE,
					FAMILIARI_OGIM FAOG,
					PRATICHE_TRIBUTO PRTR
				WHERE
					TARI.TIPO_TARIFFA (+) = OGPR.TIPO_TARIFFA AND
					TARI.CATEGORIA (+) = OGPR.CATEGORIA AND
					TARI.TRIBUTO (+) = OGPR.TRIBUTO AND
					TARI.ANNO (+) = :p_anno AND
					CATE.CATEGORIA (+) = OGPR.CATEGORIA AND
					CATE.TRIBUTO (+) = OGPR.TRIBUTO AND
					OGGE.COD_VIA = AVIE.COD_VIA (+) AND
					OGIM.COD_FISCALE (+) = OGCR.COD_FISCALE AND
					OGIM.OGGETTO_PRATICA (+) = OGCR.OGGETTO_PRATICA AND
					OGGE.OGGETTO = OGPR.OGGETTO AND
					OGPR.OGGETTO_PRATICA = OGCR.OGGETTO_PRATICA AND
					PRTR.PRATICA_RIF = :p_pratica AND
					(OGPR.PRATICA = PRTR.PRATICA AND OGIM.FLAG_CALCOLO IS NULL) AND
					OGIM.OGGETTO_IMPOSTA = FAOG.OGGETTO_IMPOSTA (+)
				GROUP BY
					OGPR.OGGETTO_PRATICA,
					OGGE.OGGETTO,
					OGGE.NUM_CIV,
					OGGE.SUFFISSO,
					OGGE.SCALA,
					OGGE.PIANO,
					OGGE.INTERNO,
					OGGE.COD_VIA,
					OGCR.PERC_POSSESSO,
					OGPR.PRATICA,
					OGGE.ANNO_CATASTO,
					OGGE.SEZIONE,
					OGGE.FOGLIO,
					OGGE.NUMERO,
					OGGE.SUBALTERNO,
					OGGE.ZONA,
					OGGE.PARTITA,
					OGGE.PROTOCOLLO_CATASTO,
					OGPR.TIPO_OGGETTO,
					OGPR.CONSISTENZA,
					decode(OGGE.COD_VIA,NULL,INDIRIZZO_LOCALITA,DENOM_UFF||
												decode(NUM_CIV,NULL,'',','||NUM_CIV )||
												decode(SUFFISSO,NULL,'','/'||SUFFISSO )||
												decode(INTERNO,NULL,'',' INT. '||INTERNO)),
					OGPR.CATEGORIA,
					OGPR.TIPO_TARIFFA,
					OGPR.TRIBUTO,
					OGCR.INIZIO_OCCUPAZIONE,
					OGCR.FINE_OCCUPAZIONE,
					OGCR.DATA_DECORRENZA,
					OGCR.DATA_CESSAZIONE,
					OGCR.FLAG_AB_PRINCIPALE,
					nvl(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO),
					OGPR.TIPO_OCCUPAZIONE,
					nvl(OGPR.CLASSE_CATASTO,OGGE.CLASSE_CATASTO),
					TARI.TIPO_TARIFFA||' - '||substr(TARI.DESCRIZIONE,1,30),
					CATE.CATEGORIA||' - '||substr(CATE.DESCRIZIONE,1,20),
					decode(CATE.FLAG_DOMESTICA,'S',FAOG.NUMERO_FAMILIARI,NULL),
					decode(CATE.FLAG_DOMESTICA,'S',FAOG.DAL,NULL),
					decode(CATE.FLAG_DOMESTICA,'S',FAOG.AL,NULL),
					CATE.FLAG_DOMESTICA
				ORDER BY
					nvl(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO) ASC,
					OGGE.OGGETTO ASC,
					OGGE.SEZIONE ASC,
					OGGE.FOGLIO ASC,
					OGGE.NUMERO ASC,
					OGGE.SUBALTERNO ASC,
					CATE.FLAG_DOMESTICA,
					OGCR.INIZIO_OCCUPAZIONE,
					decode(CATE.FLAG_DOMESTICA,'S',FAOG.DAL,NULL)
		"""

        def results = eseguiQuery("${sql}", filtri, null, true)

        def oggetti = []

        results.each {

            def result = [
                    oggetto         : [:],
                    pratica         : [:],
                    categoriaCatasto: [:]
            ]

            result.id = it['OGGETTO_PRATICA'] as Long
            result.oggetto.id = it['OGGETTO'] as Long
            result.pratica.id = it['PRATICA'] as Long

            result.oggetto.tipoOggetto = it['TIPO_OGGETTO'] as String
            result.oggetto.indirizzo = it['INDIRIZZO_OGG'] as String
            result.oggetto.sezione = it['SEZIONE'] as String
            result.oggetto.foglio = it['FOGLIO'] as String
            result.oggetto.numero = it['NUMERO'] as String
            result.oggetto.subalterno = it['SUBALTERNO'] as String
            result.oggetto.classeCatasto = it['CLASSE_CATASTO'] as String

            result.categoriaCatasto.categoriaCatasto = it['CATEGORIA_CATASTO'] as String

            result.codiceTributo = it['TRIBUTO'] as Long
            result.categoria = it['CATEGORIA'] as Long
            result.desCategoria = it['CATE_DESCR'] as String
            result.tipoTariffa = it['TIPO_TARIFFA'] as Long
            result.desTipoTariffa = it['TARI_DESCR'] as String
            result.tipoOccupazione = it['TIPO_OCCUPAZIONE'] as String
            result.consistenza = it['CONSISTENZA'] as BigDecimal

            result.dataDecorrenza = it['DATA_DECORRENZA']
            result.dataCessazione = it['DATA_CESSAZIONE']
            result.inizioOccupazione = it['INIZIO_OCCUPAZIONE']
            result.fineOccupazione = it['FINE_OCCUPAZIONE']
            result.percPossesso = it['PERC_POSSESSO'] as Double
            result.flagAbPrincipale = (it['FLAG_AB_PRINCIPALE'] == 'S')
            result.numeroFamiliari = it['NUMERO_FAMILIARI'] as Long
            result.familiariDal = it['FAOG_DAL']
            result.familiariAl = it['FAOG_AL']

            result.impostaLorda = it['IMPOSTA_LORDA'] as Double
            result.maggTARES = it['MAGGIORAZIONE_TARES'] as Double

            oggetti << result
        }

        return oggetti
    }

    def getDichiaratoAccertamentoManualeTribMin(Long idPratica, String codFiscale, short anno) {

        List listaDichiarati = []

        OggettoPratica oggettoPraticaDichiarato = getOggettoPraticaDichiarato(idPratica)

        //se l'oggettoPraticaRif non è valorizzato il Dichiarato non va visualizzato
        if (oggettoPraticaDichiarato?.oggettoPraticaRif?.id) {

            BigDecimal valoreImpostaNetta
            BigDecimal valoreImpostaLorda
            //Connection conn = DataSourceUtils.getConnection(dataSource)
            Sql sql = new Sql(dataSource)
            sql.call('{? = call f_get_imposta_netta_per_ogpr(?, ?, ?)}'
                    , [Sql.DECIMAL, oggettoPraticaDichiarato.oggettoPraticaRif.id
                       , anno
                       , codFiscale]) { valoreImpostaNetta = it }
            sql.call('{? = call f_get_imposta_lorda_per_ogpr(?, ?, ?)}'
                    , [Sql.DECIMAL, oggettoPraticaDichiarato.oggettoPraticaRif.id
                       , anno
                       , codFiscale]) { valoreImpostaLorda = it }

            def lista = OggettoPratica.createCriteria().list {
                createAlias("categoria", "cat", CriteriaSpecification.LEFT_JOIN)
                createAlias("tariffa", "tar", CriteriaSpecification.LEFT_JOIN)
                createAlias("oggettiContribuente", "oggCtr", CriteriaSpecification.INNER_JOIN)
                createAlias("oggCtr.oggettiImposta", "oggImp", CriteriaSpecification.LEFT_JOIN)
                createAlias("pratica", "prt", CriteriaSpecification.INNER_JOIN)
                createAlias("prt.tipoTributo", "tipoTri", CriteriaSpecification.INNER_JOIN)
                createAlias("tipoTri.codiciTributo", "codTri", CriteriaSpecification.INNER_JOIN)

                projections {
                    groupProperty("consistenza")
                    groupProperty("oggCtr.inizioOccupazione")
                    groupProperty("oggCtr.dataDecorrenza")
                    groupProperty("oggCtr.fineOccupazione")
                    groupProperty("oggCtr.dataCessazione")
                    groupProperty("prt.data")
                    groupProperty("codiceTributo.id")
                    groupProperty("cat.categoria")
                    groupProperty("cat.descrizione")
                    groupProperty("tar.tipoTariffa")
                    groupProperty("tar.descrizione")
                    groupProperty("oggCtr.percPossesso")
                    groupProperty("tipoOccupazione")
                    groupProperty("oggCtr.flagAbPrincipale")
                    groupProperty("numeroFamiliari")
                }

                or {
                    isNull("oggImp.anno")
                    eq("oggImp.anno", anno)
                }
                eq("oggCtr.contribuente.codFiscale", codFiscale)
                eq("id", oggettoPraticaDichiarato.oggettoPraticaRif.id)
            }

            def listaDic = [:]
            for (oggettoPrt in lista) {

                listaDic.superficie = oggettoPrt[0]
                listaDic.inizioOcc = oggettoPrt[1]
                listaDic.decorrenza = oggettoPrt[2]
                listaDic.fineOcc = oggettoPrt[3]
                listaDic.cessazione = oggettoPrt[4]
                listaDic.imposta = valoreImpostaNetta
                listaDic.impostaLorda = valoreImpostaLorda
                listaDic.data = oggettoPrt[5]
                listaDic.codTributo = oggettoPrt[6]
                listaDic.categoria = oggettoPrt[7] + " - " + oggettoPrt[8]
                listaDic.tariffa = oggettoPrt[9] + " - " + oggettoPrt[10]
                listaDic.percPossesso = oggettoPrt[11]
                listaDic.occupazione = oggettoPrt[12]
                listaDic.flagAbPrincipale = oggettoPrt[13]
                listaDic.numFamiliari = oggettoPrt[14]

                listaDichiarati << listaDic
            }
        }
        return listaDichiarati
    }

    def getAccertatoAccertamentoManualeTribMin(Long idPratica, String codFiscale, short anno) {

        def listaAcc = []
        def parametriQuery = [:]
        parametriQuery.pIdPratica = idPratica
        parametriQuery.pCodFiscale = codFiscale
        parametriQuery.pAnno = anno

        String sql = """
          			SELECT
					  oggPrtAcc.consistenza,
					  oggCtr.inizioOccupazione,
					  oggCtr.dataDecorrenza,
					  oggCtr.fineOccupazione,
					  oggCtr.dataCessazione,
					  decode(decode(ruolo.id,null,coalesce(cata.flagLordo,'N'),coalesce(ruolo.importoLordo,'N'))
						,'S',decode(codTri.flagRuolo
				  		,'S',round(oggImpAcc.imposta * nvl(cata.addizionaleEca,0) / 100,2)    +
					   	round(oggImpAcc.imposta * nvl(cata.maggiorazioneEca,0) / 100,2)  +
					   	round(oggImpAcc.imposta * nvl(cata.addizionalePro,0) / 100,2)    +
					  	round(oggImpAcc.imposta * nvl(cata.aliquota, 0) / 100,2),0),0) + oggImpAcc.imposta as imposta,
	 				  oggPrtAcc.codiceTributo.id,
					  oggPrtAcc.categoria.categoria,
					  oggPrtAcc.categoria.descrizione,
					  oggPrtAcc.tipoTariffa,
					  oggPrtAcc.tariffa.descrizione,
					  oggCtr.flagAbPrincipale,
					  oggPrtAcc.tipoOccupazione,
					  oggCtr.percPossesso,
					  oggPrtAcc.numeroFamiliari			
          			FROM
						CaricoTarsu as cata,
						PraticaTributo as prt
					INNER JOIN
						prt.oggettiPratica as oggPrtAcc
					INNER JOIN
						oggPrtAcc.codiceTributo as codTri
					LEFT JOIN
						oggPrtAcc.oggettoPraticaRifAp as oggPrtRif
					LEFT JOIN
						oggPrtAcc.oggettiContribuente as oggCtr
					INNER JOIN
						oggCtr.oggettiImposta as oggImpAcc
					LEFT JOIN
						oggCtr.oggettiImposta as oggImpDic
					LEFT JOIN
						oggImpDic.ruolo as ruolo
		  			WHERE
						cata.anno = :pAnno 		
					AND oggImpAcc.anno = :pAnno 
					AND oggImpDic.anno = :pAnno 
					AND oggCtr.contribuente.codFiscale = :pCodFiscale 
					AND prt.id = :pIdPratica 
		"""

        listaAcc = PraticaTributo.executeQuery(sql, parametriQuery).collect { row ->
            [
                    superficie        : row[0]
                    , inizioOcc       : row[1]
                    , decorrenza      : row[2]
                    , fineOcc         : row[3]
                    , cessazione      : row[4]
                    , imposta         : row[5]
                    , codTributo      : row[6]
                    , categoria       : row[7] + " " + row[8]
                    , tariffa         : row[9] + " " + row[10]
                    , flagAbPrincipale: row[11]
                    , occupazione     : row[12]
                    , percPossesso    : row[13]
                    , numFamiliari    : row[14]
            ]
        }
    }

    // Ricava id OggettoPraticaRif di OggettoContribuente
    def getOggettoPratricaRif(OggettoContribuenteDTO oggettoContribuente) {

        def oggettoRif = [:]

        Long oggPrRifId = oggettoContribuente.oggettoPratica?.oggettoPraticaRifV?.id
        if (oggPrRifId == null) {
            oggPrRifId = oggettoContribuente.oggettoPratica?.oggettoPraticaRif?.id
        }

        oggettoRif.id = oggPrRifId

        return oggettoRif
    }

    // Ricava dati principali OggettoPraticaRif
    def getDatiOggettoPratricaRif(OggettoContribuenteDTO oggettoContribuente, Short anno) {

        def oggettoRif = getOggettoPratricaRif(oggettoContribuente)

        if (oggettoRif.id != null) {

            String codFiscale = oggettoContribuente.contribuente.codFiscale
            String tipoTributo = oggettoContribuente.oggettoPratica.pratica.tipoTributo.tipoTributo

            def oggettiPraticaIDs = [oggettoRif.id]
            def oggettiPratica = getDatiOggettiPratricaRif(tipoTributo, codFiscale, anno, oggettiPraticaIDs)
            if (oggettiPratica.size() > 0) {
                oggettoRif = oggettiPratica[0]
            }
        }

        return oggettoRif
    }

    // Ricava dati principali elenco Oggetti Pratica
    def getDatiOggettiPratricaRif(String tipoTributo, String codFiscale, Short anno, def oggettiPraticaIDs) {

        if (!tipoTributo in ['ICI', 'TARSU']) {
            throw new Exception("Tipo tributo ${tipoTributo} non supportato !")
        }

        def filtri = [:]

        def oggettiIDs = oggettiPraticaIDs.isEmpty() ? "(-1)" : "(" + oggettiPraticaIDs?.join(",") + ")"

        filtri << ['codFiscale': codFiscale]
        filtri << ['anno': anno]

        String sql

        if (tipoTributo == 'ICI') {
            sql = """
				SELECT
					OGPR.OGGETTO_PRATICA AS OGGETTO_PRATICA,
					OGPR.NUM_ORDINE AS NUM_ORDINE,
					OGPR.OGGETTO AS OGGETTO_ID,
					OGPR.OGGETTO_PRATICA AS OGG_PRAT_ACC_ID,
					'Dic.' AS OGG_PRAT_ACC_TIPO,
					NVL(OGPR.TIPO_OGGETTO,OGGE.TIPO_OGGETTO) AS TIPO_OGGETTO,
					DECODE(OGGE.COD_VIA,NULL,OGGE.INDIRIZZO_LOCALITA,ARVI.DENOM_UFF) || ', ' || OGGE.NUM_CIV ||
						DECODE(SUFFISSO, NULL, '', '/' || SUFFISSO) ||
				--		DECODE(SCALA, NULL, '', ' Sc.' || SCALA) ||
				--		DECODE(PIANO, NULL, '', ' P.' || PIANO) ||
						DECODE(INTERNO, NULL, '', ' int.' || INTERNO) INDIRIZZO,
					OGGE.SEZIONE,
					OGGE.FOGLIO,
					OGGE.NUMERO,
					OGGE.SUBALTERNO,
					NVL(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO) AS CATEGORIA_CATASTO,
					OGGE.CLASSE_CATASTO AS CLASSE_CATASTO,
					OGGE.ZONA,
					OGGE.PARTITA,
					OGPR.TRIBUTO AS CODICE_TRIBUTO,
					COTR.DESCRIZIONE AS DES_CODICE_TRIBUTO,
					OGPR.CATEGORIA,
					CATE.DESCRIZIONE AS DES_CATEGORIA,
					OGPR.TIPO_TARIFFA,
					TARI.DESCRIZIONE AS DES_TARIFFA,
					OGPR.FLAG_CONTENZIOSO,
					OGPR.TIPO_OCCUPAZIONE,
					DECODE(OGPR.TIPO_OCCUPAZIONE,'P','Permanente','T','Temporanea','-') as DES_TIPO_OCCUPAZIONE,
					OGPR.OGGETTO_PRATICA_RIF_AP,
					OGPR_AP.OGGETTO AS OGGETTO_RIF_AP,
					OGPR.NUMERO_FAMILIARI,
					OGPR.CONSISTENZA,
					OGCO.DATA_DECORRENZA,
					OGCO.DATA_CESSAZIONE,
					OGCO.INIZIO_OCCUPAZIONE,
					OGCO.FINE_OCCUPAZIONE,
					OGCO.PERC_POSSESSO,
					decode(:anno,PRAT.ANNO,OGCO.MESI_POSSESSO,12) MESI_POSSESSO,
					decode(:anno,PRAT.ANNO,OGCO.MESI_POSSESSO_1SEM,6) MESI_POSSESSO_1SEM,
					decode(:anno,PRAT.ANNO,
							decode(OGCO.FLAG_ESCLUSIONE,'S',
							   nvl(OGCO.MESI_ESCLUSIONE,nvl(OGCO.MESI_POSSESSO,12)),
							   OGCO.MESI_ESCLUSIONE),						
							decode(OGCO.FLAG_ESCLUSIONE,'S',12,NULL)) MESI_ESCLUSIONE,
					decode(:anno,PRAT.ANNO,
							decode(OGCO.FLAG_RIDUZIONE,'S',
							   nvl(OGCO.MESI_RIDUZIONE,nvl(OGCO.MESI_POSSESSO,12)),
							   OGCO.MESI_RIDUZIONE),						
							decode(OGCO.FLAG_RIDUZIONE,'S',12,NULL)) MESI_RIDUZIONE,
					decode(:anno,PRAT.ANNO,OGCO.MESI_OCCUPATO,12) MESI_OCCUPATO,
					decode(:anno,PRAT.ANNO,OGCO.MESI_OCCUPATO_1SEM,6) MESI_OCCUPATO_1SEM,
					OGCO.MESI_ALIQUOTA_RIDOTTA,
					decode(:anno,PRAT.ANNO,OGCO.DA_MESE_POSSESSO,1) DA_MESE_POSSESSO,
					OGCO.FLAG_POSSESSO,
					OGCO.FLAG_ESCLUSIONE,
					OGCO.FLAG_RIDUZIONE,
					OGCO.FLAG_AB_PRINCIPALE,
					OGPR.IMM_STORICO,
					OGPR.FLAG_PROVVISORIO,
					OGPR.TIPO_QUALITA,
					OGPR.QUALITA,
					OGPR.TITOLO,
					OGPR.ESTREMI_TITOLO,
					OGCO.DATA_EVENTO,
					OGPR.MODELLO,
					OGPR.NOTE,
					PRAT.PRATICA AS PRATICA,
					PRAT.ANNO AS ANNO_PRATICA,
					PRAT.DATA AS DATA_PRATICA,
					f_scadenza_denuncia(PRAT.TIPO_TRIBUTO,PRAT.ANNO) AS SCADENZA_DENUNCIA,
					OGPR.ANNO AS ANNO_OGPR,
					OGIM.IMPOSTA AS IMPOSTA,
					OGIM.IMPOSTA_ACCONTO AS IMPOSTA_ACCONTO,
					OGIM.IMPORTO_VERSATO AS IMPORTO_VERSATO,
					OGIM.TIPO_ALIQUOTA AS TIPO_ALIQUOTA,
					OGIM.ALIQUOTA AS ALIQUOTA,
					TIAL.DESCRIZIONE AS DES_ALIQUOTA,
					nvl(to_number(f_max_riog(OGPR.OGGETTO_PRATICA,:anno,'RE')),
						F_RENDITA(OGPR.VALORE
								,nvl(OGPR.TIPO_OGGETTO,OGGE.TIPO_OGGETTO)
								,OGPR.ANNO
								,nvl(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO)
							  )
					) AS RENDITA,
					nvl(F_VALORE((to_number(f_max_riog(OGPR.OGGETTO_PRATICA,:anno,'RE')) *
								decode(OGGE.TIPO_OGGETTO
									  ,1,nvl(molt.moltiplicatore,1)
									  ,3,nvl(molt.moltiplicatore,1)
									  ,1
									  )
							   )
							 , OGGE.TIPO_OGGETTO
							 , 1996
							 , :anno
							 , ' '
							 ,PRAT.TIPO_PRATICA
							 ,OGPR.FLAG_VALORE_RIVALUTATO
							 )
						, F_VALORE(OGPR.VALORE
								 , NVL(OGPR.TIPO_OGGETTO,OGGE.TIPO_OGGETTO)
								 , PRAT.ANNO
								 , :anno
								 ,NVL(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO)
								 ,PRAT.TIPO_PRATICA
								 ,OGPR.FLAG_VALORE_RIVALUTATO
								 )
					) AS VALORE
				FROM
					OGGETTI OGGE,
					OGGETTI_PRATICA OGPR,
					OGGETTI_CONTRIBUENTE OGCO,
					OGGETTI_IMPOSTA OGIM,
					TIPI_ALIQUOTA TIAL,
					PRATICHE_TRIBUTO PRAT,
					CODICI_TRIBUTO COTR,
					CATEGORIE CATE,
					TARIFFE TARI,
					ARCHIVIO_VIE ARVI,
					MOLTIPLICATORI MOLT,
					OGGETTI_PRATICA OGPR_AP
				WHERE
					OGGE.OGGETTO = OGPR.OGGETTO AND
					OGGE.COD_VIA = ARVI.COD_VIA(+) AND
					OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA AND
					OGPR.ANNO = OGCO.ANNO AND
					PRAT.PRATICA = OGPR.PRATICA AND
					OGPR.TRIBUTO = COTR.TRIBUTO(+) AND
					OGPR.TRIBUTO = CATE.TRIBUTO(+) AND
					OGPR.CATEGORIA = CATE.CATEGORIA(+) AND
					OGPR.TRIBUTO = TARI.TRIBUTO(+) AND
					OGPR.CATEGORIA = TARI.CATEGORIA(+) AND
					OGPR.TIPO_TARIFFA = TARI.TIPO_TARIFFA(+) AND
					OGPR.ANNO = TARI.ANNO (+) AND
					OGIM.TIPO_TRIBUTO = TIAL.TIPO_TRIBUTO (+) AND
					OGIM.TIPO_ALIQUOTA = TIAL.TIPO_ALIQUOTA (+) AND
					OGCO.OGGETTO_PRATICA = OGIM.OGGETTO_PRATICA (+) AND  
					OGCO.COD_FISCALE = OGIM.COD_FISCALE (+) AND
					OGIM.ANNO(+) = :anno AND
					OGPR.OGGETTO_PRATICA IN ${oggettiIDs} AND
					MOLT.ANNO(+) = :anno AND
					MOLT.CATEGORIA_CATASTO(+) = f_max_riog(OGPR.OGGETTO_PRATICA,:anno,'CA') AND
					OGCO.COD_FISCALE = :codFiscale AND
					OGPR.OGGETTO_PRATICA_RIF_AP = OGPR_AP.OGGETTO_PRATICA (+)
		"""

        } else if (tipoTributo == 'TARSU') {
            sql = """
				SELECT
					OGPR.OGGETTO_PRATICA AS OGGETTO_PRATICA,
					OGPR.NUM_ORDINE AS NUM_ORDINE,
					OGPR.OGGETTO AS OGGETTO_ID,
					OGPR.OGGETTO_PRATICA AS OGG_PRAT_ACC_ID,
					'Dic.' AS OGG_PRAT_ACC_TIPO,
					NVL(OGPR.TIPO_OGGETTO,OGGE.TIPO_OGGETTO) AS TIPO_OGGETTO,
					DECODE(OGGE.COD_VIA,NULL,OGGE.INDIRIZZO_LOCALITA,ARVI.DENOM_UFF) || ', ' || OGGE.NUM_CIV ||
						DECODE(SUFFISSO, NULL, '', '/' || SUFFISSO) ||
				--		DECODE(SCALA, NULL, '', ' Sc.' || SCALA) ||
				--		DECODE(PIANO, NULL, '', ' P.' || PIANO) ||
						DECODE(INTERNO, NULL, '', ' int.' || INTERNO) INDIRIZZO,
					OGGE.SEZIONE,
					OGGE.FOGLIO,
					OGGE.NUMERO,
					OGGE.SUBALTERNO,
					NVL(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO) AS CATEGORIA_CATASTO,
					OGGE.CLASSE_CATASTO AS CLASSE_CATASTO,
					OGGE.ZONA,
					OGGE.PARTITA,
					OGPR.VALORE AS VALORE,
					OGPR.TRIBUTO AS CODICE_TRIBUTO,
					COTR.DESCRIZIONE AS DES_CODICE_TRIBUTO,
					OGPR.CATEGORIA,
					CATE.DESCRIZIONE AS DES_CATEGORIA,
					OGPR.TIPO_TARIFFA,
					TARI.DESCRIZIONE AS DES_TARIFFA,
					OGPR.FLAG_CONTENZIOSO,
					OGPR.TIPO_OCCUPAZIONE,
					DECODE(OGPR.TIPO_OCCUPAZIONE,'P','Permanente','T','Temporanea','-') as DES_TIPO_OCCUPAZIONE,
					OGPR.OGGETTO_PRATICA_RIF_AP,
					OGPR_AP.OGGETTO AS OGGETTO_RIF_AP,
					OGPR.NUMERO_FAMILIARI,
					OGPR.CONSISTENZA,
					OGCO.DATA_DECORRENZA,
					OGCO.DATA_CESSAZIONE,
					OGCO.INIZIO_OCCUPAZIONE,
					OGCO.FINE_OCCUPAZIONE,
					OGCO.PERC_POSSESSO,
					OGCO.MESI_POSSESSO,
					OGCO.MESI_POSSESSO_1SEM,
					OGCO.MESI_OCCUPATO,
					OGCO.MESI_OCCUPATO_1SEM,
					OGCO.MESI_ESCLUSIONE,
					OGCO.MESI_RIDUZIONE,
					OGCO.MESI_ALIQUOTA_RIDOTTA,
					OGCO.DA_MESE_POSSESSO,
					OGCO.FLAG_POSSESSO,
					OGCO.FLAG_ESCLUSIONE,
					OGCO.FLAG_RIDUZIONE,
					OGCO.FLAG_AB_PRINCIPALE,
					OGPR.IMM_STORICO,
					OGPR.FLAG_PROVVISORIO,
					OGPR.TIPO_QUALITA,
					OGPR.QUALITA,
					OGPR.TITOLO,
					OGPR.ESTREMI_TITOLO,
					OGCO.DATA_EVENTO,
					OGPR.MODELLO,
					OGPR.NOTE,
					PRAT.PRATICA AS PRATICA,
                    PRAT.TIPO_PRATICA AS TIPO_PRATICA,
					PRAT.ANNO AS ANNO_PRATICA,
					PRAT.DATA AS DATA_PRATICA,
					f_scadenza_denuncia(PRAT.TIPO_TRIBUTO,PRAT.ANNO) AS SCADENZA_DENUNCIA,
					OGPR.ANNO AS ANNO_OGPR,
					f_get_imposta_netta_per_ogpr(OGPR.OGGETTO_PRATICA,:anno,OGCO.COD_FISCALE) AS IMPOSTA,
					f_get_imposta_lorda_per_ogpr(OGPR.OGGETTO_PRATICA,:anno,OGCO.COD_FISCALE) AS IMPOSTA_LORDA,
					f_get_imposta_netta_per_ogpr(OGPR.OGGETTO_PRATICA,:anno,OGCO.COD_FISCALE,'P') AS IMPOSTA_PERIODO,
					f_get_imposta_lorda_per_ogpr(OGPR.OGGETTO_PRATICA,:anno,OGCO.COD_FISCALE,'P') AS IMPOSTA_PERIODO_LORDA,
					f_get_magg_tares_per_ogpr(OGPR.OGGETTO_PRATICA,:anno,OGCO.COD_FISCALE) AS MAGG_TARES,
                    OGCO.FLAG_PUNTO_RACCOLTA AS FLAG_PUNTO_RACCOLTA
				FROM
					OGGETTI OGGE,
					OGGETTI_PRATICA OGPR,
					OGGETTI_CONTRIBUENTE OGCO,
					PRATICHE_TRIBUTO PRAT,
					CODICI_TRIBUTO COTR,
					CATEGORIE CATE,
					TARIFFE TARI,
					ARCHIVIO_VIE ARVI,
					OGGETTI_PRATICA OGPR_AP
				WHERE
					OGGE.OGGETTO = OGPR.OGGETTO AND
					OGGE.COD_VIA = ARVI.COD_VIA(+) AND
					OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA AND
					OGPR.ANNO = OGCO.ANNO AND
					PRAT.PRATICA = OGPR.PRATICA AND
					OGPR.TRIBUTO = COTR.TRIBUTO(+) AND
					OGPR.TRIBUTO = CATE.TRIBUTO(+) AND
					OGPR.CATEGORIA = CATE.CATEGORIA(+) AND
					OGPR.TRIBUTO = TARI.TRIBUTO(+) AND
					OGPR.CATEGORIA = TARI.CATEGORIA(+) AND
					OGPR.TIPO_TARIFFA = TARI.TIPO_TARIFFA(+) AND
					OGPR.ANNO = TARI.ANNO (+) AND
					OGPR.OGGETTO_PRATICA IN ${oggettiIDs} AND
					OGCO.COD_FISCALE = :codFiscale AND
					OGPR.OGGETTO_PRATICA_RIF_AP = OGPR_AP.OGGETTO_PRATICA (+)
		"""
        }

        def results = eseguiQuery("${sql}", filtri, null, true)
        def oggetti = []

        results.each { row ->
            oggetti << getDatiDichLiqFromRow(row)
        }

        return oggetti
    }

    // Ricava dati principali Liquidazione OggettoPraticaRif
    def getDatiOggettoPratricaLiq(OggettoContribuenteDTO oggettoContribuente, Short anno) {

        def oggettoRif = getOggettoPratricaRif(oggettoContribuente)

        if (oggettoRif.id != null) {

            String codFiscale = oggettoContribuente.contribuente.codFiscale
            String tipoTributo = oggettoContribuente.oggettoPratica.pratica.tipoTributo.tipoTributo

            def oggettiPraticaIDs = [oggettoRif.id]
            def oggettiPratica = getDatiOggettiPratricaLiq(tipoTributo, codFiscale, anno, oggettiPraticaIDs)
            if (oggettiPratica.size() > 0) {
                oggettoRif = oggettiPratica[0]
            }
        }

        return oggettoRif
    }

    // Ricava dati principali Liquidazione Oggetti Pratica
    def getDatiOggettiPratricaLiq(String tipoTributo, String codFiscale, Short anno, def oggettiPraticaIDs) {

        if (!tipoTributo in ['ICI']) {
            throw new Exception("Tipo tributo ${tipoTributo} non supportato !")
        }

        def filtri = [:]

        def oggettiIDs = oggettiPraticaIDs.isEmpty() ? "(-1)" : "(" + oggettiPraticaIDs?.join(",") + ")"

        filtri << ['codFiscale': codFiscale]
        filtri << ['anno': anno]

        String sql

        if (tipoTributo == 'ICI') {
            sql = """
				SELECT
					OGPR.OGGETTO_PRATICA AS OGGETTO_PRATICA,
					OGPR.NUM_ORDINE AS NUM_ORDINE,
					OGPR.OGGETTO AS OGGETTO_ID,
					OGPR.OGGETTO_PRATICA_RIF AS OGG_PRAT_ACC_ID,
					'Liq.' AS OGG_PRAT_ACC_TIPO,
					NVL(OGPR.TIPO_OGGETTO,OGGE.TIPO_OGGETTO)  AS TIPO_OGGETTO,
					DECODE(OGGE.COD_VIA,NULL,OGGE.INDIRIZZO_LOCALITA,ARVI.DENOM_UFF) || ', ' || OGGE.NUM_CIV ||
						DECODE(SUFFISSO, NULL, '', '/' || SUFFISSO) ||
				--		DECODE(SCALA, NULL, '', ' Sc.' || SCALA) ||
				--		DECODE(PIANO, NULL, '', ' P.' || PIANO) ||
						DECODE(INTERNO, NULL, '', ' int.' || INTERNO) INDIRIZZO,
					OGGE.SEZIONE,
					OGGE.FOGLIO,
					OGGE.NUMERO,
					OGGE.SUBALTERNO,
					NVL(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO) AS CATEGORIA_CATASTO,
					OGGE.CLASSE_CATASTO AS CLASSE_CATASTO,
					OGGE.ZONA,
					OGGE.PARTITA,
					OGPR.VALORE AS VALORE,
					OGPR.TRIBUTO AS CODICE_TRIBUTO,
					COTR.DESCRIZIONE AS DES_CODICE_TRIBUTO,
					OGPR.CATEGORIA,
					CATE.DESCRIZIONE AS DES_CATEGORIA,
					OGPR.TIPO_TARIFFA,
					TARI.DESCRIZIONE AS DES_TARIFFA,
					OGPR.FLAG_CONTENZIOSO,
					OGPR.TIPO_OCCUPAZIONE,
					DECODE(OGPR.TIPO_OCCUPAZIONE,'P','Permanente','T','Temporanea','-') as DES_TIPO_OCCUPAZIONE,
					NULL AS OGGETTO_PRATICA_RIF_AP,
					NULL AS OGGETTO_RIF_AP,
					OGPR.NUMERO_FAMILIARI,
					OGPR.CONSISTENZA,
					OGCO.DATA_DECORRENZA,
					OGCO.DATA_CESSAZIONE,
					OGCO.INIZIO_OCCUPAZIONE,
					OGCO.FINE_OCCUPAZIONE,
					OGCO.PERC_POSSESSO,
					OGCO.MESI_POSSESSO,
					OGCO.MESI_POSSESSO_1SEM,
					OGCO.MESI_OCCUPATO,
					OGCO.MESI_OCCUPATO_1SEM,
					OGCO.MESI_ESCLUSIONE,
					OGCO.MESI_RIDUZIONE,
					OGCO.MESI_ALIQUOTA_RIDOTTA,
					OGCO.DA_MESE_POSSESSO,
					OGCO.FLAG_POSSESSO,
					OGCO.FLAG_ESCLUSIONE,
					OGCO.FLAG_RIDUZIONE,
					OGCO.FLAG_AB_PRINCIPALE,
					OGPR.IMM_STORICO,
					OGPR.FLAG_PROVVISORIO,
					OGPR.TIPO_QUALITA,
					OGPR.QUALITA,
					OGPR.TITOLO,
					OGPR.ESTREMI_TITOLO,
					OGCO.DATA_EVENTO,
					OGPR.MODELLO,
					OGPR.NOTE,
					PRAT.PRATICA AS PRATICA,
					PRAT.ANNO AS ANNO_PRATICA,
					PRAT.DATA AS DATA_PRATICA,
					f_scadenza_denuncia(PRAT.TIPO_TRIBUTO,PRAT.ANNO) AS SCADENZA_DENUNCIA,
					OGPR.ANNO AS ANNO_OGPR,
					OGIM.IMPOSTA AS IMPOSTA,
					OGIM.IMPOSTA_ACCONTO AS IMPOSTA_ACCONTO,
					OGIM.IMPORTO_VERSATO AS IMPORTO_VERSATO,
					OGIM.TIPO_ALIQUOTA AS TIPO_ALIQUOTA,
					OGIM.ALIQUOTA AS ALIQUOTA,
					TIAL.DESCRIZIONE AS DES_ALIQUOTA,
					f_rendita(OGPR.VALORE,nvl(OGPR.tipo_oggetto,OGGE.TIPO_OGGETTO),:anno,nvl(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO)) AS RENDITA 
				FROM
					OGGETTI_CONTRIBUENTE OGCO,
					OGGETTI_PRATICA OGPR,
					OGGETTI OGGE,
					OGGETTI_IMPOSTA OGIM,
					PRATICHE_TRIBUTO PRAT,
					TIPI_ALIQUOTA TIAL,
					CODICI_TRIBUTO COTR,
					CATEGORIE CATE,
					TARIFFE TARI,
					ARCHIVIO_VIE ARVI
				WHERE
					PRAT.TIPO_PRATICA = 'L' AND
					PRAT.TIPO_EVENTO = 'U' AND
					PRAT.ANNO = :anno AND
					PRAT.PRATICA = OGPR.PRATICA AND
					PRAT.DATA_NOTIFICA IS NOT NULL AND
					OGIM.ANNO(+) = :anno AND
					OGIM.COD_FISCALE(+) = OGCO.COD_FISCALE AND
					OGIM.OGGETTO_PRATICA(+) = OGCO.OGGETTO_PRATICA AND
					OGCO.COD_FISCALE = :codFiscale AND
					OGCO.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
					OGPR.OGGETTO = OGGE.OGGETTO AND
					OGPR.OGGETTO_PRATICA_RIF IN ${oggettiIDs} AND
					OGGE.COD_VIA = ARVI.COD_VIA(+) AND
					OGPR.TRIBUTO = COTR.TRIBUTO(+) AND
					OGPR.TRIBUTO = CATE.TRIBUTO(+) AND
					OGPR.CATEGORIA = CATE.CATEGORIA(+) AND
					OGPR.TRIBUTO = TARI.TRIBUTO(+) AND
					OGPR.CATEGORIA = TARI.CATEGORIA(+) AND
					OGPR.TIPO_TARIFFA = TARI.TIPO_TARIFFA(+) AND
					OGIM.TIPO_TRIBUTO = TIAL.TIPO_TRIBUTO (+) AND
					OGIM.TIPO_ALIQUOTA = TIAL.TIPO_ALIQUOTA (+) AND
					(NOT EXISTS
						(SELECT 1 
						 FROM
							OGGETTI_CONTRIBUENTE OGCO_LIQ, 
							OGGETTI_PRATICA OGPR_LIQ, 
							OGGETTI_IMPOSTA OGIM_LIQ,
							PRATICHE_TRIBUTO PRTR_LIQ
						WHERE
							PRTR_LIQ.TIPO_PRATICA = 'L' AND 
							PRTR_LIQ.TIPO_EVENTO = 'R' AND
							PRTR_LIQ.ANNO = :anno AND
							PRTR_LIQ.PRATICA = OGPR_LIQ.PRATICA AND 
							PRTR_LIQ.DATA_NOTIFICA IS NOT NULL AND 
							OGIM_LIQ.ANNO(+) = :anno AND
							OGIM_LIQ.COD_FISCALE(+) = OGCO_LIQ.COD_FISCALE AND
							OGIM_LIQ.OGGETTO_PRATICA(+) = OGCO_LIQ.OGGETTO_PRATICA AND 
							OGCO_LIQ.COD_FISCALE = :codFiscale AND
							OGCO_LIQ.OGGETTO_PRATICA = OGPR_LIQ.OGGETTO_PRATICA AND 
							OGPR_LIQ.OGGETTO_PRATICA_RIF IN ${oggettiIDs}
						)
					) 
				UNION
				SELECT
					OGPR.OGGETTO_PRATICA AS OGGETTO_PRATICA,
					OGPR.NUM_ORDINE AS NUM_ORDINE,
					OGPR.OGGETTO AS OGGETTO_ID,
					OGPR.OGGETTO_PRATICA_RIF AS OGG_PRAT_ACC_ID,
					'Liq.' AS OGG_PRAT_ACC_TIPO,
					NVL(OGPR.TIPO_OGGETTO,OGGE.TIPO_OGGETTO) AS TIPO_OGGETTO,
					DECODE(OGGE.COD_VIA,NULL,OGGE.INDIRIZZO_LOCALITA,ARVI.DENOM_UFF) || ', ' || OGGE.NUM_CIV ||
						DECODE(SUFFISSO, NULL, '', '/' || SUFFISSO) ||
				--		DECODE(SCALA, NULL, '', ' Sc.' || SCALA) ||
				--		DECODE(PIANO, NULL, '', ' P.' || PIANO) ||
						DECODE(INTERNO, NULL, '', ' int.' || INTERNO) INDIRIZZO,
					OGGE.SEZIONE,
					OGGE.FOGLIO,
					OGGE.NUMERO,
					OGGE.SUBALTERNO,
					NVL(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO) AS CATEGORIA_CATASTO,
					OGGE.CLASSE_CATASTO AS CLASSE_CATASTO,
					OGGE.ZONA,
					OGGE.PARTITA,
					OGPR.VALORE AS VALORE,
					OGPR.TRIBUTO AS CODICE_TRIBUTO,
					COTR.DESCRIZIONE AS DES_CODICE_TRIBUTO,
					OGPR.CATEGORIA,
					CATE.DESCRIZIONE AS DES_CATEGORIA,
					OGPR.TIPO_TARIFFA,
					TARI.DESCRIZIONE AS DES_TARIFFA,
					OGPR.FLAG_CONTENZIOSO,
					OGPR.TIPO_OCCUPAZIONE,
					DECODE(OGPR.TIPO_OCCUPAZIONE,'P','Permanente','T','Temporanea','-') as DES_TIPO_OCCUPAZIONE,
					NULL AS OGGETTO_PRATICA_RIF_AP,
					NULL AS OGGETTO_RIF_AP,
					OGPR.NUMERO_FAMILIARI,
					OGPR.CONSISTENZA,
					OGCO.DATA_DECORRENZA,
					OGCO.DATA_CESSAZIONE,
					OGCO.INIZIO_OCCUPAZIONE,
					OGCO.FINE_OCCUPAZIONE,
					OGCO.PERC_POSSESSO,
					OGCO.MESI_POSSESSO,
					OGCO.MESI_POSSESSO_1SEM,
					OGCO.MESI_OCCUPATO,
					OGCO.MESI_OCCUPATO_1SEM,
					OGCO.MESI_ESCLUSIONE,
					OGCO.MESI_RIDUZIONE,
					OGCO.MESI_ALIQUOTA_RIDOTTA,
					OGCO.DA_MESE_POSSESSO,
					OGCO.FLAG_POSSESSO,
					OGCO.FLAG_ESCLUSIONE,
					OGCO.FLAG_RIDUZIONE,
					OGCO.FLAG_AB_PRINCIPALE,
					OGPR.IMM_STORICO,
					OGPR.FLAG_PROVVISORIO,
					OGPR.TIPO_QUALITA,
					OGPR.QUALITA,
					OGPR.TITOLO,
					OGPR.ESTREMI_TITOLO,
					OGCO.DATA_EVENTO,
					OGPR.MODELLO,
					OGPR.NOTE,
					PRAT.PRATICA AS PRATICA,
					PRAT.ANNO AS ANNO_PRATICA,
					PRAT.DATA AS DATA_PRATICA,
					f_scadenza_denuncia(PRAT.TIPO_TRIBUTO,PRAT.ANNO) AS SCADENZA_DENUNCIA,
					OGPR.ANNO AS ANNO_OGPR,
					OGIM.IMPOSTA AS IMPOSTA,
					OGIM.IMPOSTA_ACCONTO AS IMPOSTA_ACCONTO,
					OGIM.IMPORTO_VERSATO AS IMPORTO_VERSATO,
					OGIM.TIPO_ALIQUOTA AS TIPO_ALIQUOTA,
					OGIM.ALIQUOTA AS ALIQUOTA,
					TIAL.DESCRIZIONE AS DES_ALIQUOTA,
					f_rendita(OGPR.VALORE,nvl(OGPR.tipo_oggetto,OGGE.TIPO_OGGETTO),:anno,nvl(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO)) AS RENDITA 
				FROM
					OGGETTI_CONTRIBUENTE OGCO,
					OGGETTI_PRATICA OGPR,
					OGGETTI OGGE,
					OGGETTI_IMPOSTA OGIM,
					PRATICHE_TRIBUTO PRAT,
					TIPI_ALIQUOTA TIAL,
					CODICI_TRIBUTO COTR,
					CATEGORIE CATE,
					TARIFFE TARI,
					ARCHIVIO_VIE ARVI
				WHERE
					PRAT.TIPO_PRATICA = 'L' AND
					PRAT.TIPO_EVENTO = 'R' AND
					PRAT.ANNO = :anno AND
					PRAT.PRATICA = OGPR.PRATICA AND
					PRAT.DATA_NOTIFICA IS NOT NULL AND
					OGIM.ANNO(+) = :anno AND
					OGIM.COD_FISCALE(+) = OGCO.COD_FISCALE AND
					OGIM.OGGETTO_PRATICA(+) = OGCO.OGGETTO_PRATICA AND
					OGCO.COD_FISCALE = :codFiscale AND
					OGCO.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
					OGPR.OGGETTO = OGGE.OGGETTO AND
					OGPR.OGGETTO_PRATICA_RIF IN ${oggettiIDs} AND
					OGGE.COD_VIA = ARVI.COD_VIA(+) AND
					OGPR.TRIBUTO = COTR.TRIBUTO(+) AND
					OGPR.TRIBUTO = CATE.TRIBUTO(+) AND
					OGPR.CATEGORIA = CATE.CATEGORIA(+) AND
					OGPR.TRIBUTO = TARI.TRIBUTO(+) AND
					OGPR.CATEGORIA = TARI.CATEGORIA(+) AND
					OGPR.TIPO_TARIFFA = TARI.TIPO_TARIFFA(+) AND
					OGIM.TIPO_TRIBUTO = TIAL.TIPO_TRIBUTO (+) AND
					OGIM.TIPO_ALIQUOTA = TIAL.TIPO_ALIQUOTA (+)
		"""
        }

        def results = eseguiQuery("${sql}", filtri, null, true)
        def oggetti = []

        results.each { row ->
            oggetti << getDatiDichLiqFromRow(row)
        }

        return oggetti
    }

    // Estrae dati Oggetti Pratica da row del dataset
    def getDatiDichLiqFromRow(def row) {

        def oggetto = [:]

        oggetto.id = row['OGGETTO_PRATICA'] as Long
        oggetto.numOrdine = row['NUM_ORDINE'] as String
        oggetto.oggettoId = row['OGGETTO_ID'] as Long
        oggetto.oggPrAccId = row['OGG_PRAT_ACC_ID'] as Long
        oggetto.oggPrAccTipo = row['OGG_PRAT_ACC_TIPO'] as String

        oggetto.tipoOggetto = row['TIPO_OGGETTO'] as Long
        oggetto.indirizzo = row['INDIRIZZO'] as String
        oggetto.sezione = row['SEZIONE'] as String
        oggetto.foglio = row['FOGLIO'] as String
        oggetto.numero = row['NUMERO'] as String
        oggetto.subalterno = row['SUBALTERNO'] as String
        oggetto.categoriaCatasto = row['CATEGORIA_CATASTO'] as String
        oggetto.classeCatasto = row['CLASSE_CATASTO'] as String
        oggetto.zona = row['ZONA'] as String
        oggetto.partita = row['PAERTITA'] as String
        oggetto.codiceTributo = row['CODICE_TRIBUTO'] as Long
        oggetto.desCodiceTributo = row['DES_CODICE_TRIBUTO'] as String
        oggetto.categoria = row['CATEGORIA'] as Long
        oggetto.desCategoria = row['DES_CATEGORIA'] as String
        oggetto.tipoTariffa = row['TIPO_TARIFFA'] as Long
        oggetto.desTipoTariffa = row['DES_TARIFFA'] as String
        oggetto.tipoOccupazione = row['TIPO_OCCUPAZIONE'] as String
        oggetto.desTipoOccupazione = row['DES_TIPO_OCCUPAZIONE'] as String
        oggetto.flagContenzioso = (row['FLAG_CONTENZIOSO'] == 'S')
        oggetto.consistenza = row['CONSISTENZA'] as Double
        oggetto.numeroFamiliari = row['NUMERO_FAMILIARI'] as Long
        oggetto.dataDecorrenza = row['DATA_DECORRENZA']
        oggetto.dataCessazione = row['DATA_CESSAZIONE']
        oggetto.inizioOccupazione = row['INIZIO_OCCUPAZIONE']
        oggetto.fineOccupazione = row['FINE_OCCUPAZIONE']

        oggetto.oggettoPraticaRifAp = row['OGGETTO_PRATICA_RIF_AP'] as Long
        oggetto.oggettoRifAp = row['OGGETTO_RIF_AP'] as String

        oggetto.rendita = row['RENDITA'] as Double
        oggetto.valore = row['VALORE'] as Double

        oggetto.percPossesso = row['PERC_POSSESSO'] as Double
        oggetto.mesiPossesso = row['MESI_POSSESSO'] as Short
        oggetto.mesiPossesso1sem = row['MESI_POSSESSO_1SEM'] as Short
        oggetto.mesiOccupato = row['MESI_OCCUPATO'] as Short
        oggetto.mesiOccupato1sem = row['MESI_OCCUPATO_1SEM'] as Short
        oggetto.mesiEsclusione = row['MESI_ESCLUSIONE'] as Short
        oggetto.mesiRiduzione = row['MESI_RIDUZIONE'] as Short
        oggetto.mesiAliquotaRidotta = row['MESI_ALIQUOTA_RIDOTTA'] as Short
        oggetto.daMesePossesso = row['DA_MESE_POSSESSO'] as Short

        oggetto.flagPossesso = (row['FLAG_POSSESSO'] == 'S')
        oggetto.flagEsclusione = (row['FLAG_ESCLUSIONE'] == 'S')
        oggetto.flagRiduzione = (row['FLAG_RIDUZIONE'] == 'S')
        oggetto.flagAbPrincipale = (row['FLAG_AB_PRINCIPALE'] == 'S')
        oggetto.flagPuntoRaccolta = (row['FLAG_PUNTO_RACCOLTA'] == 'S')

        oggetto.immStorico = (row['IMM_STORICO'] == 'S')
        oggetto.flagProvvisorio = (row['FLAG_PROVVISORIO'] == 'S')
        oggetto.tipoQualita = row['TIPO_QUALITA'] as Short
        oggetto.qualita = row['QUALITA'] as String
        oggetto.titolo = row['TITOLO'] as String
        oggetto.estremiTitolo = row['ESTREMI_TITOLO'] as String
        oggetto.dataEvento = row['DATA_EVENTO']
        oggetto.modello = row['MODELLO'] as Short
        oggetto.note = row['NOTE'] as String

        oggetto.pratica = row['PRATICA'] as Long
        oggetto.tipoPratica = row['TIPO_PRATICA'] as String
        oggetto.annoPratica = row['ANNO_PRATICA'] as Short
        oggetto.dataPratica = row['DATA_PRATICA']
        oggetto.scadenzaDenuncia = row['SCADENZA_DENUNCIA']
        oggetto.annoOgPr = row['ANNO_OGPR'] as Short

        oggetto.versato = row['IMPORTO_VERSATO'] as Double
        oggetto.tipoAliquota = row['TIPO_ALIQUOTA'] as Integer
        oggetto.aliquota = row['ALIQUOTA'] as Double
        oggetto.desAliquotaFull = row['DES_ALIQUOTA'] as String

        if ((oggetto.desAliquotaFull?.size() ?: 0) > 32) {
            oggetto.desAliquota = oggetto.desAliquotaFull.substring(0, 32) + "…"
        } else {
            oggetto.desAliquota = oggetto.desAliquotaFull
        }

        oggetto.impostaTotale = row['IMPOSTA'] as Double
        oggetto.impostaTotaleLorda = row['IMPOSTA_LORDA'] as Double
        oggetto.impostaPeriodo = row['IMPOSTA_PERIODO'] as Double
        oggetto.impostaPeriodoLorda = row['IMPOSTA_PERIODO_LORDA'] as Double
        oggetto.impostaAcconto = row['IMPOSTA_ACCONTO'] as Double

        oggetto.maggTARES = row['MAGG_TARES'] as Double

        oggetto.imposta = row['IMPOSTA_PERIODO'] ? oggetto.impostaPeriodo : oggetto.impostaTotale
        oggetto.impostaLorda = row['IMPOSTA_PERIODO_LORDA'] ? oggetto.impostaPeriodoLorda : oggetto.impostaTotaleLorda

        return oggetto
    }

    // Ricava elenco oggetti accertabili per contribuente : al momento la query è specifica per TARSU.
    def getOggettiAccertabili(String tipoTributo, String codFiscale, Short anno) {

        def filtri = [:]

        if (!(tipoTributo in ['ICI', 'TARSU'])) {
            throw new Exception("Tipo tributo ${tipoTributo} non supportato !")
        }

        String sql

        filtri << ['tipoTributo': tipoTributo]
        filtri << ['codFiscale': codFiscale]
        filtri << ['anno': anno]

        if (tipoTributo == 'ICI') {
            sql = """
				SELECT
					(SELECT DECODE(MAX(PRTR_ACC.NUMERO),'','','S')
							FROM PRATICHE_TRIBUTO PRTR_ACC, OGGETTI_PRATICA OGPR_ACC
							WHERE PRTR_ACC.PRATICA = OGPR_ACC.PRATICA
							  AND PRTR_ACC.TIPO_PRATICA = 'A'
							  AND OGPR.OGGETTO_PRATICA = NVL(OGPR_ACC.OGGETTO_PRATICA_RIF_V,OGPR_ACC.OGGETTO_PRATICA_RIF)
					) ACCERTATO,
					(SELECT MAX(DECODE(PRTR_ACC.NUMERO,NULL,'('||TO_CHAR(PRTR_ACC.PRATICA)||')',TO_CHAR(PRTR_ACC.NUMERO))|| 
								DECODE(PRTR_ACC.DATA,NULL,NULL,' del '||TO_CHAR(PRTR_ACC.DATA,'DD/mm/yyyy')))
						FROM PRATICHE_TRIBUTO PRTR_ACC, OGGETTI_PRATICA OGPR_ACC
						WHERE PRTR_ACC.PRATICA = OGPR_ACC.PRATICA
							  AND PRTR_ACC.TIPO_PRATICA = 'A'
							  AND OGPR.OGGETTO_PRATICA = NVL(OGPR_ACC.OGGETTO_PRATICA_RIF_V,OGPR_ACC.OGGETTO_PRATICA_RIF)
					) ACCERTAMENTO,
					OGGE.OGGETTO AS OGGETTO_ID,
					OGPR.OGGETTO_PRATICA,
					OGGE.COD_VIA,
					OGGE.NUM_CIV,
					OGGE.SUFFISSO,
					OGGE.INTERNO,
					OGGE.INDIRIZZO_LOCALITA,
					ARVI.DENOM_UFF,
					OGGE.SEZIONE,
					OGGE.FOGLIO,
					OGGE.NUMERO,
					OGGE.SUBALTERNO,
					OGGE.ZONA,
					OGGE.PARTITA,
					OGGE.PROTOCOLLO_CATASTO,
					OGGE.ANNO_CATASTO,
					OGPR.TIPO_OGGETTO,
					f_max_riog(OGPR.OGGETTO_PRATICA,:anno,'CA') CATEGORIA_CATASTO,
					f_max_riog(OGPR.OGGETTO_PRATICA,:anno,'CL') CLASSE_CATASTO,
					nvl(to_number(f_max_riog(OGPR.OGGETTO_PRATICA,:anno,'RE')),
						F_RENDITA(OGPR.VALORE
								,nvl(OGPR.TIPO_OGGETTO,OGGE.TIPO_OGGETTO)
								,OGPR.ANNO
								,nvl(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO)
							  )
					) RENDITA,
					nvl(F_VALORE((to_number(f_max_riog(OGPR.OGGETTO_PRATICA,:anno,'RE')) *
								decode(OGGE.TIPO_OGGETTO
									  ,1,nvl(molt.moltiplicatore,1)
									  ,3,nvl(molt.moltiplicatore,1)
									  ,1
									  )
							   )
							 , OGGE.TIPO_OGGETTO
							 , 1996
							 , :anno
							 , ' '
							 ,PRTR.TIPO_PRATICA
							 ,OGPR.FLAG_VALORE_RIVALUTATO
							 )
						, F_VALORE(OGPR.VALORE
								 , NVL(OGPR.TIPO_OGGETTO,OGGE.TIPO_OGGETTO)
								 , PRTR.ANNO
								 , :anno
								 ,NVL(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO)
								 ,PRTR.TIPO_PRATICA
								 ,OGPR.FLAG_VALORE_RIVALUTATO
								 )
					) VALORE,
					OGCO.PERC_POSSESSO,
					decode(:anno,PRTR.ANNO,OGCO.MESI_POSSESSO,12) MESI_POSSESSO,
					decode(:anno,PRTR.ANNO,OGCO.MESI_POSSESSO_1SEM,6) MESI_POSSESSO_1SEM,
					decode(:anno,PRTR.ANNO,OGCO.DA_MESE_POSSESSO,1) DA_MESE_POSSESSO,
					decode(OGCO.FLAG_ESCLUSIONE,'S',12,null) MESI_ESCLUSIONE,
					decode(OGCO.FLAG_RIDUZIONE,'S',12,null) MESI_RIDUZIONE,
					OGCO.FLAG_POSSESSO,
					OGCO.FLAG_ESCLUSIONE,
					OGCO.FLAG_RIDUZIONE,
					OGCO.FLAG_AB_PRINCIPALE,
					OGCO.DATA_DECORRENZA,
					OGCO.DATA_CESSAZIONE,
					decode(OGGE.COD_VIA, NULL,INDIRIZZO_LOCALITA, DENOM_UFF||decode(NUM_CIV,NULL,'', ', '||NUM_CIV)
																	||decode(SUFFISSO,NULL,'', '/'||SUFFISSO )) INDIRIZZO,
					OGPR.FLAG_PROVVISORIO,
					OGCO.DETRAZIONE,
					PRTR.ANNO,
					F_ESISTE_DETRAZIONE_OGCO(OGCO.OGGETTO_PRATICA,OGCO.COD_FISCALE,:tipoTributo) DETRAZIONE_OGCO,
					F_ESISTE_ALIQUOTA_OGCO(OGCO.OGGETTO_PRATICA,OGCO.COD_FISCALE,:tipoTributo) ALIQUOTA_OGCO,
					OGPR.FLAG_VALORE_RIVALUTATO,
					PRTR.TIPO_EVENTO TIPO_EVENTO,
					PRTR.TIPO_PRATICA TIPO_PRATICA
				FROM
					ARCHIVIO_VIE ARVI,
					OGGETTI OGGE,
					MOLTIPLICATORI MOLT,
					PRATICHE_TRIBUTO PRTR,
					OGGETTI_PRATICA OGPR,
					OGGETTI_CONTRIBUENTE OGCO
				WHERE
					prtr.tipo_tributo         = :tipoTributo and
					ogge.cod_via              = arvi.cod_via (+) and
					OGCO.OGGETTO_PRATICA      = OGPR.OGGETTO_PRATICA and
					MOLT.ANNO(+)              = :anno AND
					MOLT.CATEGORIA_CATASTO(+) = f_max_riog(OGPR.OGGETTO_PRATICA,:anno,'CA') AND
					OGPR.PRATICA              = PRTR.PRATICA and
					OGPR.OGGETTO              = OGGE.OGGETTO and
					((PRTR.TIPO_PRATICA||'' <> 'A') OR
					 (PRTR.TIPO_PRATICA||'' = 'A' and PRTR.DATA_NOTIFICA is not null and 
					  nvl(PRTR.STATO_ACCERTAMENTO,'D') = 'D' and nvl(PRTR.FLAG_DENUNCIA,' ') = 'S')) AND 
					OGCO.COD_FISCALE          = :codFiscale and
					OGCO.FLAG_POSSESSO        = 'S' and
					(OGCO.ANNO||OGCO.TIPO_RAPPORTO||'S') =
						(SELECT max (OGCO_SUB.ANNO||OGCO_SUB.TIPO_RAPPORTO||OGCO_SUB.FLAG_POSSESSO)
							 FROM PRATICHE_TRIBUTO PRTR_SUB,
								  OGGETTI_PRATICA OGPR_SUB,
								  OGGETTI_CONTRIBUENTE OGCO_SUB
							WHERE PRTR_SUB.TIPO_TRIBUTO||''  = :tipoTributo and
								  ((PRTR_SUB.TIPO_PRATICA||'' = 'D' and
								    PRTR_SUB.DATA_NOTIFICA is null) or
								   (PRTR_SUB.TIPO_PRATICA||'' = 'A' and
								    PRTR_SUB.DATA_NOTIFICA is not null and
								    nvl(PRTR_SUB.STATO_ACCERTAMENTO,'D') = 'D' and
								    nvl(PRTR_SUB.FLAG_DENUNCIA,' ') = 'S' and
								    PRTR_SUB.ANNO <= :anno)
								  ) and
								  PRTR_SUB.PRATICA           = OGPR_SUB.PRATICA and
								  OGCO_SUB.ANNO             <= :anno          and
								  OGCO_SUB.COD_FISCALE       = OGCO.COD_FISCALE and
								  OGCO_SUB.OGGETTO_PRATICA   = OGPR_SUB.OGGETTO_PRATICA and
								  OGPR_SUB.OGGETTO           = OGPR.OGGETTO
						)
				UNION
				SELECT
					(SELECT DECODE(MAX(PRTR_ACC.NUMERO),'','','S')
							FROM PRATICHE_TRIBUTO PRTR_ACC, OGGETTI_PRATICA OGPR_ACC
							WHERE PRTR_ACC.PRATICA = OGPR_ACC.PRATICA
							  AND PRTR_ACC.TIPO_PRATICA = 'A'
							  AND OGPR.OGGETTO_PRATICA = NVL(OGPR_ACC.OGGETTO_PRATICA_RIF_V,OGPR_ACC.OGGETTO_PRATICA_RIF)
					) ACCERTATO,
					(SELECT MAX(DECODE(PRTR_ACC.NUMERO,NULL,'('||TO_CHAR(PRTR_ACC.PRATICA)||')',TO_CHAR(PRTR_ACC.NUMERO))||
								DECODE(PRTR_ACC.DATA,NULL,NULL,' del '||TO_CHAR(PRTR_ACC.DATA,'DD/mm/yyyy')))
						FROM PRATICHE_TRIBUTO PRTR_ACC, OGGETTI_PRATICA OGPR_ACC
						WHERE PRTR_ACC.PRATICA = OGPR_ACC.PRATICA
							  AND PRTR_ACC.TIPO_PRATICA = 'A'
							  AND OGPR.OGGETTO_PRATICA = NVL(OGPR_ACC.OGGETTO_PRATICA_RIF_V,OGPR_ACC.OGGETTO_PRATICA_RIF)
					) ACCERTAMENTO,
					OGGE.OGGETTO AS OGGETTO_ID,
					OGPR.OGGETTO_PRATICA,
					OGGE.COD_VIA,
					OGGE.NUM_CIV,
					OGGE.SUFFISSO,
					OGGE.INTERNO,
					OGGE.INDIRIZZO_LOCALITA,
					ARVI.DENOM_UFF,
					OGGE.SEZIONE,
					OGGE.FOGLIO,
					OGGE.NUMERO,
					OGGE.SUBALTERNO,
					OGGE.ZONA,
					OGGE.PARTITA,
					OGGE.PROTOCOLLO_CATASTO,
					OGGE.ANNO_CATASTO,
					OGGE.TIPO_OGGETTO,
					f_max_riog(OGPR.OGGETTO_PRATICA,:anno,'CA') CATEGORIA_CATASTO,
					f_max_riog(OGPR.OGGETTO_PRATICA,:anno,'CL') CLASSE_CATASTO,
					nvl(to_number(f_max_riog(OGPR.OGGETTO_PRATICA,:anno,'RE')),
						F_RENDITA(OGPR.VALORE
								,NVL(OGPR.TIPO_OGGETTO,OGGE.TIPO_OGGETTO)
								,OGPR.ANNO
								,NVL(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO)
							  )
					) RENDITA,
					nvl(F_VALORE((to_number(f_max_riog(OGPR.OGGETTO_PRATICA,:anno,'RE')) *
								decode(OGGE.TIPO_OGGETTO
									  ,1,nvl(molt.moltiplicatore,1)
									  ,3,nvl(molt.moltiplicatore,1)
									  ,1
									  )
							   )
							 , OGGE.TIPO_OGGETTO
							 , 1996
							 , :anno
							 ,' '
							 ,PRTR.TIPO_PRATICA
							 ,OGPR.FLAG_VALORE_RIVALUTATO
							 )
						, F_VALORE(OGPR.VALORE,NVL(OGPR.TIPO_OGGETTO,OGGE.TIPO_OGGETTO)
								 , PRTR.ANNO
								 , :anno
								 , NVL(OGPR.CATEGORIA_CATASTO,OGGE.CATEGORIA_CATASTO)
								 , PRTR.TIPO_PRATICA
								 , OGPR.FLAG_VALORE_RIVALUTATO
								 )
					) VALORE,
					OGCO.PERC_POSSESSO,
					decode(:anno,PRTR.ANNO,OGCO.MESI_POSSESSO,12) MESI_POSSESSO,
					decode(:anno,PRTR.ANNO,OGCO.MESI_POSSESSO_1SEM,6) MESI_POSSESSO_1SEM,
					decode(:anno,PRTR.ANNO,OGCO.DA_MESE_POSSESSO,1) DA_MESE_POSSESSO,
					decode(OGCO.FLAG_ESCLUSIONE,'S',12,null) MESI_ESCLUSIONE,
					decode(OGCO.FLAG_RIDUZIONE,'S',12,null) MESI_RIDUZIONE,
					OGCO.FLAG_POSSESSO,
					OGCO.FLAG_ESCLUSIONE,
					OGCO.FLAG_RIDUZIONE,
					OGCO.FLAG_AB_PRINCIPALE,
					OGCO.DATA_DECORRENZA,
					OGCO.DATA_CESSAZIONE,
					decode(OGGE.COD_VIA,NULL,INDIRIZZO_LOCALITA,DENOM_UFF||decode(NUM_CIV,NULL,'', ', '||NUM_CIV)
											||decode(SUFFISSO,NULL,'', '/'||SUFFISSO )||decode(INTERNO,NULL,'',' int. '||INTERNO)),
					OGPR.FLAG_PROVVISORIO,
					OGCO.DETRAZIONE,
					PRTR.ANNO,
					F_ESISTE_DETRAZIONE_OGCO(OGCO.OGGETTO_PRATICA,OGCO.COD_FISCALE,:tipoTributo) DETRAZIONE_OGCO,
					F_ESISTE_ALIQUOTA_OGCO(OGCO.OGGETTO_PRATICA,OGCO.COD_FISCALE,:tipoTributo) ALIQUOTA_OGCO,
					OGPR.FLAG_VALORE_RIVALUTATO,
					PRTR.TIPO_EVENTO TIPO_EVENTO,
					PRTR.TIPO_PRATICA TIPO_PRATICA
				FROM
					ARCHIVIO_VIE ARVI,
					MOLTIPLICATORI MOLT,
					OGGETTI OGGE,
					PRATICHE_TRIBUTO PRTR,
					OGGETTI_PRATICA OGPR,
					OGGETTI_CONTRIBUENTE OGCO
				WHERE
					OGGE.COD_VIA              = ARVI.COD_VIA (+) AND
					MOLT.ANNO(+)              = :anno AND
					MOLT.CATEGORIA_CATASTO(+) = f_max_riog(OGPR.OGGETTO_PRATICA,:anno,'CA') AND
					OGCO.OGGETTO_PRATICA      = OGPR.OGGETTO_PRATICA AND
					OGPR.PRATICA              = PRTR.PRATICA AND
					OGPR.OGGETTO              = OGGE.OGGETTO AND
					PRTR.TIPO_TRIBUTO||''     = :tipoTributo AND
					PRTR.TIPO_PRATICA||''  in ('V','D') AND
					OGCO.FLAG_POSSESSO     IS NULL AND
					OGCO.COD_FISCALE          = :codFiscale AND
					OGCO.ANNO                 = :anno
				ORDER BY
					SEZIONE,
					FOGLIO,
					NUMERO,
					SUBALTERNO,
					OGGETTO_ID
			"""
        } else {
            if (tipoTributo == 'TARSU') {
                sql = """
				SELECT DISTINCT
					(SELECT DECODE(MAX(PRTR_ACC.NUMERO),'','','S')
				            FROM PRATICHE_TRIBUTO PRTR_ACC, OGGETTI_PRATICA OGPR_ACC
				            WHERE PRTR_ACC.PRATICA = OGPR_ACC.PRATICA
				              AND PRTR_ACC.TIPO_PRATICA = 'A'
				              AND OGPR.OGGETTO_PRATICA = NVL(OGPR_ACC.OGGETTO_PRATICA_RIF_V,OGPR_ACC.OGGETTO_PRATICA_RIF)
					) ACCERTATO,
					OGCO.OGGETTO_PRATICA,
					OGCO.DATA_DECORRENZA,
					f_fine_validita(OGCO.OGGETTO_PRATICA,OGCO.COD_FISCALE,OGCO.DATA_DECORRENZA,'D') DATA_CESSAZIONE,
					PRTR.TIPO_EVENTO TIPO_EVENTO,
					OGGE.OGGETTO AS OGGETTO_ID,
					OGGE.SEZIONE,
					OGGE.FOGLIO,
					OGGE.NUMERO,
					OGGE.SUBALTERNO,
					OGGE.ZONA,
					OGGE.PARTITA,
					OGGE.PROTOCOLLO_CATASTO,
					OGGE.ANNO_CATASTO,
					OGGE.TIPO_OGGETTO,
					f_max_riog(OGPR.OGGETTO_PRATICA,:anno,'CA') CATEGORIA_CATASTO,
					f_max_riog(OGPR.OGGETTO_PRATICA,:anno,'CL') CLASSE_CATASTO,
					OGPR.CONSISTENZA CONSISTENZA,
					OGPR.TRIBUTO TRIBUTO,
					OGPR.CATEGORIA CATEGORIA,
					OGPR.TIPO_TARIFFA TIPO_TARIFFA,
					(SELECT MAX(DECODE(PRTR_ACC.NUMERO,NULL,'('||TO_CHAR(PRTR_ACC.PRATICA)||')',TO_CHAR(PRTR_ACC.NUMERO))||
								DECODE(PRTR_ACC.DATA,NULL,NULL,' del '||TO_CHAR(PRTR_ACC.DATA,'DD/mm/yyyy')))
						FROM PRATICHE_TRIBUTO PRTR_ACC, OGGETTI_PRATICA OGPR_ACC
						WHERE PRTR_ACC.PRATICA = OGPR_ACC.PRATICA
				              AND PRTR_ACC.TIPO_PRATICA = 'A'
				              AND OGPR.OGGETTO_PRATICA = NVL(OGPR_ACC.OGGETTO_PRATICA_RIF_V,OGPR_ACC.OGGETTO_PRATICA_RIF)
					) ACCERTAMENTO,
					decode(OGGE.COD_VIA,NULL,INDIRIZZO_LOCALITA,ARVE.DENOM_UFF ||
								DECODE(NUM_CIV,NULL,'', ', ' || NUM_CIV ) || DECODE( SUFFISSO,NULL,'', '/' ||SUFFISSO )) INDIRIZZO,
					PRTR.TIPO_PRATICA TIPO_PRATICA
				FROM
					OGGETTI OGGE,
					PRATICHE_TRIBUTO PRTR,
					OGGETTI_PRATICA OGPR,
					OGGETTI_CONTRIBUENTE OGCO,
					ARCHIVIO_VIE ARVE
				WHERE
					EXISTS
					(SELECT 'x' FROM RUOLI, OGGETTI_IMPOSTA OGIM
					  WHERE RUOLI.INVIO_CONSORZIO   IS NOT NULL
						AND RUOLI.RUOLO = OGIM.RUOLO
						AND OGIM.ANNO = :anno
						AND OGIM.COD_FISCALE = :codFiscale
						AND OGIM.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA )
					AND OGGE.COD_VIA = ARVE.COD_VIA (+)
					AND OGGE.OGGETTO = OGPR.OGGETTO
					AND PRTR.TIPO_PRATICA IN ('A','D')
					AND decode(PRTR.TIPO_PRATICA,'A',PRTR.FLAG_DENUNCIA,'S') = 'S'
					AND nvl(PRTR.STATO_ACCERTAMENTO,'D') = 'D'
					AND NVL(TO_NUMBER(TO_CHAR(f_fine_validita(OGCO.OGGETTO_PRATICA,OGCO.COD_FISCALE,
																			OGCO.DATA_DECORRENZA,'D'),'YYYY')),:anno) >= :anno
					AND nvl(TO_NUMBER(TO_CHAR(OGCO.DATA_DECORRENZA,'YYYY')),1900) <= :anno
					AND PRTR.TIPO_TRIBUTO||'' = :tipoTributo
					AND PRTR.PRATICA = OGPR.PRATICA
					AND OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA
					AND OGCO.COD_FISCALE = :codFiscale
				ORDER BY 5 ASC
			"""
            }
        }

        def results = eseguiQuery("${sql}", filtri, null, true)

        def oggetti = []

        results.each {

            def oggetto = [:]

            oggetto.id = it['OGGETTO_PRATICA'] as Long
            oggetto.oggettoId = it['OGGETTO_ID'] as Long
            oggetto.tipoOggetto = it['TIPO_OGGETTO'] as String
            oggetto.tipoEvento = it['TIPO_EVENTO'] as String
            oggetto.tipoPratica = it['TIPO_PRATICA'] as String

            oggetto.indirizzo = it['INDIRIZZO'] as String
            oggetto.sezione = it['SEZIONE'] as String
            oggetto.foglio = it['FOGLIO'] as String
            oggetto.numero = it['NUMERO'] as String
            oggetto.subalterno = it['SUBALTERNO'] as String

            oggetto.zona = it['ZONA'] as String
            oggetto.categoriaCat = it['CATEGORIA_CATASTO'] as String
            oggetto.classeCat = it['CLASSE_CATASTO'] as String
            oggetto.protocolloCat = it['PROTOCOLLO_CATASTO'] as String
            oggetto.annoCat = it['ANNO_CATASTO'] as Short
            oggetto.partita = it['PARTITA'] as String

            oggetto.dataDecorrenza = it['DATA_DECORRENZA']
            oggetto.dataCessazione = it['DATA_CESSAZIONE']

            // ICI
            oggetto.perPoss = it['PERC_POSSESSO'] as Double
            oggetto.mesiPoss = it['MESI_POSSESSO'] as Short
            oggetto.mesiPoss1S = it['MESI_POSSESSO_1SEM'] as Short
            oggetto.mesiEscl = it['MESI_ESCLUSIONE'] as Short
            oggetto.mesiRiduz = it['MESI_RIDUZIONE'] as Short

            oggetto.flagPoss = it['FLAG_POSSESSO'] as String
            oggetto.flagEscl = it['FLAG_ESCLUSIONE'] as String
            oggetto.flagRiduz = it['FLAG_RIDUZIONE'] as String
            oggetto.flagAbPrinc = it['FLAG_AB_PRINCIPALE'] as String

            oggetto.rendita = it['RENDITA'] as Double
            oggetto.valore = it['VALORE'] as Double

            oggetto.flagProvv = it['FLAG_PROVVISORIO'] as String
            oggetto.detrazione = it['DETRAZIONE'] as Double
            oggetto.aliqOgCo = it['ALIQUOTA_OGCO'] as String
            oggetto.detrazOgCo = it['DETRAZIONE_OGCO'] as String

            // T.R.
            oggetto.codiceTributo = it['TRIBUTO'] as Long
            oggetto.categoria = it['CATEGORIA'] as Long
            oggetto.tipoTariffa = it['TIPO_TARIFFA'] as Long
            oggetto.consistenza = it['CONSISTENZA'] as Double

            oggetto.accertato = it['ACCERTATO'] as String
            oggetto.accertamento = it['ACCERTAMENTO'] as String

            oggetti << oggetto
        }

        return oggetti
    }

    // Verifica periodi intersecati per gli oggetti
    def verificaPeriodiIntersecati(def oggCo) {

        String message = ""
        Long result = 0

        def oggettiIntersecanti = []

        oggCo.each {

            OggettoContribuenteDTO outer = it

            oggCo.each {
                if (verificaPeriodiIntersecati(it, outer)) {
                    Long oggId = it.oggettoPratica.oggetto.id
                    if (oggettiIntersecanti.indexOf(oggId) < 0) {
                        oggettiIntersecanti << oggId
                    }
                }
            }
        }
        if (oggettiIntersecanti.size() > 0) {
            message = "Esistono periodi intersecanti per "
            if (oggettiIntersecanti.size() > 1) {
                message += "gli oggetti "
            } else {
                message += "l'oggetto "
            }
            message += oggettiIntersecanti.join(",")
            result = 2
        }

        return [result: result, message: message]
    }

    // Verifica periodi intersecati tra due oggetti
    def verificaPeriodiIntersecati(OggettoContribuenteDTO one, OggettoContribuenteDTO two) {

        JavaDate dataIni1
        JavaDate dataFin1
        JavaDate dataIni2
        JavaDate dataFin2

        boolean result = false

        if (one != two) {
            Long ogg1 = one.oggettoPratica.oggetto.id
            Long ogg2 = two.oggettoPratica.oggetto.id

            if (ogg1 == ogg2) {
                Short anno = one.oggettoPratica.pratica.anno - 1900
                String tipoTributo = one.oggettoPratica.pratica.tipoTributo.tipoTributo

                if (tipoTributo in ['ICI']) {

                    Short oneMIP = (one.daMesePossesso ?: 1) - 1
                    Short oneMFP = (one.mesiPossesso ?: 12) - 1
                    Short twoMIP = (two.daMesePossesso ?: 1) - 1
                    Short twoMFP = (two.mesiPossesso ?: 12) - 1
                    oneMFP += oneMIP
                    if (oneMFP > 11) oneMFP = 11
                    twoMFP += twoMIP
                    if (twoMFP > 11) twoMFP = 11

                    if (((oneMIP >= twoMIP) && (oneMIP <= twoMIP)) ||
                            ((oneMFP >= twoMIP) && (oneMFP <= twoMFP))) {
                        result = true
                    }
                } else {
                    dataIni1 = one.dataDecorrenza ?: new JavaDate(1, 1, 1)
                    dataFin1 = one.dataCessazione ?: new JavaDate(1099, 12, 31)
                    dataIni2 = two.dataDecorrenza ?: new JavaDate(1, 1, 1)
                    dataFin2 = two.dataCessazione ?: new JavaDate(1099, 12, 31)

                    if (((dataIni1 >= dataIni2) && (dataIni1 <= dataFin2)) ||
                            ((dataFin1 >= dataIni2) && (dataFin1 <= dataFin2))) {
                        result = true
                    }
                }
            }
        }

        return result
    }

    // Ricava importi imposta per Oggetto Pratica - Generico
    def getImpostaOggPr(Long oggPtrId, Short anno, String codFiscale, Boolean dichiarato = false) {

        def filtri = [:]

        String sql

        def result = [
                imposta     : 0.0,
                impostaLorda: 0.0,
        ]

        filtri << ['idOggPr': oggPtrId]
        filtri << ['anno': anno]
        filtri << ['codFiscale': codFiscale]

        if (dichiarato) {
            sql = """
				SELECT
					f_get_imposta_netta_per_ogpr(:idOggPr,:anno,:codFiscale) AS IMPOSTA,
					f_get_imposta_lorda_per_ogpr(:idOggPr,:anno,:codFiscale) AS IMPOSTA_LORDA
				FROM
					DUAL
			"""
        } else {
            sql = """
				SELECT
					OGIM.IMPOSTA AS IMPOSTA,
					OGIM.IMPOSTA AS IMPOSTA_LORDA
				FROM
					OGGETTI_IMPOSTA OGIM,
					OGGETTI_PRATICA OGPR,
					CODICI_TRIBUTO COTR
				WHERE
					OGIM.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
					OGPR.TRIBUTO = COTR.TRIBUTO(+) AND
					OGIM.ANNO = :anno AND
					OGIM.OGGETTO_PRATICA = :idOggPr AND
					OGIM.COD_FISCALE = :codFiscale
			"""
        }

        def params = [:]
        params.offset = 0
        params.max = Integer.MAX_VALUE

        def results = eseguiQuery("${sql}", filtri, params)

        results.each {
            result.imposta = (it['IMPOSTA'] ?: 0) as Double
            result.impostaLorda = (it['IMPOSTA_LORDA'] ?: 0) as Double
        }

        return result
    }

    // Ricava importi imposta per Oggetto Pratica - ICI
    def getImpostaOggPrIci(Long oggPtrId, Short anno, String codFiscale, Boolean dichiarato = false) {

        def filtri = [:]

        String sql

        def result = [
                oggettoImposta     : null,
                //
                imposta            : null,
                impostaLorda       : null,
                impostaAcconto     : null,
                impostaAccontoLorda: null,
                //
                versato            : null,
                //
                tipoAliquota       : null,
                aliquota           : null,
                desAliquota        : null,
                desAliquotaFull    : null,
        ]

        filtri << ['idOggPr': oggPtrId]
        filtri << ['anno': anno]
        filtri << ['codFiscale': codFiscale]

        if (dichiarato) {
            sql = """
				SELECT
					NULL AS OGGETTO_IMPOSTA,
					f_get_imposta_netta_per_ogpr(:idOggPr,:anno,:codFiscale) AS IMPOSTA,
					f_get_imposta_lorda_per_ogpr(:idOggPr,:anno,:codFiscale) AS IMPOSTA_LORDA,
					0 AS IMPOSTA_ACCONTO,
					0 AS IMPOSTA_ACCONTO_LORDA,
					NULL AS VERSATO,
					NULL AS TIPO_ALIQUOTA,
					NULL AS ALIQUOTA,
					NULL AS DES_ALIQUOTA
				FROM
					DUAL
			"""
        } else {
            sql = """
				SELECT
					OGIM.OGGETTO_IMPOSTA AS OGGETTO_IMPOSTA,
					OGIM.IMPOSTA AS IMPOSTA,
					OGIM.IMPOSTA AS IMPOSTA_LORDA,
					OGIM.IMPOSTA_ACCONTO AS IMPOSTA_ACCONTO,
					OGIM.IMPOSTA_ACCONTO AS IMPOSTA_ACCONTO_LORDA,
					OGIM.IMPORTO_VERSATO AS IMPORTO_VERSATO, 
					OGIM.TIPO_ALIQUOTA AS TIPO_ALIQUOTA, 
					OGIM.ALIQUOTA AS ALIQUOTA,
					TIAL.DESCRIZIONE AS DES_ALIQUOTA
				FROM
					OGGETTI_IMPOSTA OGIM,
					OGGETTI_PRATICA OGPR,
					TIPI_ALIQUOTA TIAL
				WHERE
					OGIM.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
					OGIM.TIPO_ALIQUOTA = TIAL.TIPO_ALIQUOTA (+) AND
					OGIM.TIPO_TRIBUTO = TIAL.TIPO_TRIBUTO (+) AND
					OGIM.ANNO = :anno AND
					OGIM.OGGETTO_PRATICA = :idOggPr AND
					OGIM.COD_FISCALE = :codFiscale
			"""
        }

        def params = [:]
        params.offset = 0
        params.max = Integer.MAX_VALUE

        def results = eseguiQuery("${sql}", filtri, params)

        results.each {
            result.oggettoImposta = it['OGGETTO_IMPOSTA'] as Long
            result.imposta = (it['IMPOSTA'] ?: 0) as Double
            result.impostaLorda = (it['IMPOSTA_LORDA'] ?: 0) as Double
            result.impostaAcconto = (it['IMPOSTA_ACCONTO'] ?: 0) as Double
            result.impostaAccontoLorda = (it['IMPOSTA_ACCONTO_LORDA'] ?: 0) as Double
            result.versato = it['IMPORTO_VERSATO'] as Double
            result.tipoAliquota = it['TIPO_ALIQUOTA'] as Integer
            result.aliquota = it['ALIQUOTA'] as Double
            result.desAliquotaFull = it['DES_ALIQUOTA'] as String

            if ((result.desAliquotaFull?.size() ?: 0) > 32) {
                result.desAliquota = result.desAliquotaFull.substring(0, 32) + "…"
            } else {
                result.desAliquota = result.desAliquotaFull
            }
        }

        return result
    }

    // Ricava importi imposta per Oggetto Pratica (Specifico per Tari)
    def getImpostaOggPrTarsu(Long oggPtrId, Short anno, String codFiscale, Boolean dichiarato = false) {

        def filtri = [:]

        String sql

        def result = [
                oggettoImposta     : null,
                impostaTotale      : 0.0,
                impostaTotaleLorda : 0.0,
                impostaPeriodo     : null,
                impostaPeriodoLorda: null,
                imposta            : 0.0,
                impostaLorda       : 0.0,
                maggTARES          : 0.0,
                giorni             : 1,
                giorniAnno         : 1,
                periodo            : 0,
        ]

        filtri << ['idOggPr': oggPtrId]
        filtri << ['anno': anno]
        filtri << ['codFiscale': codFiscale]

        if (dichiarato) {
            sql = """
				SELECT
					NULL AS OGGETTO_IMPOSTA,
					f_get_imposta_netta_per_ogpr(:idOggPr,:anno,:codFiscale) AS IMPOSTA,
					f_get_imposta_lorda_per_ogpr(:idOggPr,:anno,:codFiscale) AS IMPOSTA_LORDA,
					f_get_imposta_netta_per_ogpr(:idOggPr,:anno,:codFiscale,'P') AS IMPOSTA_PERIODO,
					f_get_imposta_lorda_per_ogpr(:idOggPr,:anno,:codFiscale,'P') AS IMPOSTA_PERIODO_LORDA,
					f_get_magg_tares_per_ogpr(:idOggPr,:anno,:codFiscale) AS MAGG_TARES
					1 AS GIORNI,
					1 AS GIORNI_ANNO,
					1 AS PERIODO
				FROM
					DUAL
			"""
        } else {
            sql = """
				SELECT
					OGIM.OGGETTO_IMPOSTA AS OGGETTO_IMPOSTA,
					OGIM.IMPOSTA AS IMPOSTA,
					DECODE(NVL(CATA.FLAG_LORDO,'N'),'S',
						DECODE(COTR.FLAG_RUOLO
						  ,'S',ROUND(OGIM.IMPOSTA * NVL(CATA.ADDIZIONALE_ECA,0) / 100,2)    +
							 ROUND(OGIM.IMPOSTA * NVL(CATA.MAGGIORAZIONE_ECA,0) / 100,2)  +
							 ROUND(OGIM.IMPOSTA * NVL(CATA.ADDIZIONALE_PRO,0) / 100,2)    +
							 ROUND(OGIM.IMPOSTA * NVL(CATA.ALIQUOTA,0) / 100,2)
							,0
					  )
					  ,0
					) + OGIM.IMPOSTA AS IMPOSTA_LORDA,
					OGIM.IMPOSTA_PERIODO AS IMPOSTA_PERIODO,
					(CASE WHEN OGIM.IMPOSTA_PERIODO IS NOT NULL
						THEN 
							DECODE(NVL(CATA.FLAG_LORDO,'N'),'S',
							  DECODE(COTR.FLAG_RUOLO
							    ,'S',ROUND(OGIM.IMPOSTA_PERIODO * NVL(CATA.ADDIZIONALE_ECA,0) / 100,2)    +
							     ROUND(OGIM.IMPOSTA_PERIODO * NVL(CATA.MAGGIORAZIONE_ECA,0) / 100,2)  +
							     ROUND(OGIM.IMPOSTA_PERIODO * NVL(CATA.ADDIZIONALE_PRO,0) / 100,2)    +
							     ROUND(OGIM.IMPOSTA_PERIODO * NVL(CATA.ALIQUOTA,0) / 100,2)
							    ,0
							  )
							  ,0
							 ) + OGIM.IMPOSTA_PERIODO
						ELSE NULL END) AS IMPOSTA_PERIODO_LORDA,
					NVL(OGIM.MAGGIORAZIONE_TARES, 0) AS MAGG_TARES,
					(LEAST(NVL(OGCO.DATA_CESSAZIONE,TO_DATE('31129999','ddmmyyyy')),TO_DATE('3112'||:anno,'ddmmyyyy')) -
						GREATEST(NVL(OGCO.DATA_DECORRENZA,TO_DATE('01011900','ddmmyyyy')),TO_DATE('0101'||:anno,'ddmmyyyy')) + 1) AS GIORNI,
					(TO_DATE('3112'||:anno,'ddmmyyyy') - TO_DATE('0101'||:anno,'ddmmyyyy') + 1) AS GIORNI_ANNO,
					f_periodo(:anno,OGCO.DATA_DECORRENZA,OGCO.DATA_CESSAZIONE,OGPR.TIPO_OCCUPAZIONE,'TARSU','S') AS PERIODO
				FROM
					CARICHI_TARSU CATA,
					PRATICHE_TRIBUTO PRTR,
					OGGETTI_IMPOSTA OGIM,
					OGGETTI_PRATICA OGPR,
					OGGETTI_CONTRIBUENTE OGCO,
					CODICI_TRIBUTO COTR
				WHERE
					CATA.ANNO = :anno AND
					OGIM.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
					OGCO.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA AND
					OGCO.COD_FISCALE = OGIM.COD_FISCALE AND
					OGPR.PRATICA = PRTR.PRATICA AND 
					OGPR.TRIBUTO = COTR.TRIBUTO(+) AND
					OGCO.ANNO = OGIM.ANNO AND
					OGIM.ANNO = :anno AND
					OGIM.OGGETTO_PRATICA = :idOggPr AND
					OGIM.COD_FISCALE = :codFiscale
			"""
        }

        def params = [:]
        params.offset = 0
        params.max = Integer.MAX_VALUE

        def results = eseguiQuery("${sql}", filtri, params)

        results.each {
            result.oggettoImposta = it['OGGETTO_IMPOSTA'] as Long
            result.impostaTotale = (it['IMPOSTA'] ?: 0) as Double
            result.impostaTotaleLorda = (it['IMPOSTA_LORDA'] ?: 0) as Double
            result.impostaPeriodo = (it['IMPOSTA_PERIODO'] ?: 0) as Double
            result.impostaPeriodoLorda = (it['IMPOSTA_PERIODO_LORDA'] ?: 0) as Double
            result.maggTARES = (it['MAGG_TARES'] ?: 0) as Double

            result.giorni = it['GIORNI'] as Short
            result.giorniAnno = it['GIORNI_ANNO'] as Short
            result.periodo = it['PERIODO'] as Double

            result.imposta = it['IMPOSTA_PERIODO'] ? result.impostaPeriodo : result.impostaTotale
            result.impostaLorda = it['IMPOSTA_PERIODO_LORDA'] ? result.impostaPeriodoLorda : result.impostaTotaleLorda
        }

        return result
    }

    // Ricava importi Dichiarati per Oggetto Pratica
    def getDichiaratiOggPr(List<OggettoContribuenteDTO> oggetti, short anno) {

        def dichiarati = []

        oggetti.each {

            OggettoContribuenteDTO ogCo = it

            def oggettoRif = getOggettoPratricaRif(ogCo)

            if (oggettoRif.id != null) {

                def dichiarato = dichiarati.find { it.oggPrAccId == oggettoRif.id }

                if (dichiarato == null) {
                    dichiarato = getDatiOggettoPratricaRif(ogCo, anno)
                    dichiarato.riferimenti = 1

                    dichiarati << dichiarato
                } else {
                    dichiarato.riferimenti++
                }
            }
        }

        preparaDichiaratiPerAccertamento(dichiarati)

        return dichiarati
    }

    // Ricava importi Liquidati per Oggetto Pratica
    def getLiquidatiOggPr(List<OggettoContribuenteDTO> oggetti, short anno) {

        def liquidati = []

        oggetti.each {

            OggettoContribuenteDTO ogCo = it

            def oggettoRif = getOggettoPratricaRif(ogCo)

            if (oggettoRif.id != null) {

                def liquidato = liquidati.find { it.oggPrAccId == oggettoRif.id }

                if (liquidato == null) {
                    liquidato = getDatiOggettoPratricaLiq(ogCo, anno)
                    liquidato.riferimenti = 1

                    liquidati << liquidato
                } else {
                    liquidato.riferimenti++
                }
            }
        }

        preparaDichiaratiPerAccertamento(liquidati)

        return liquidati
    }

    // Prepara dati dichiarato / liquidato per gestione accertamento multi-oggetto
    // TODO : per coerenza sarebbe da cambiare nome del metodo
    def preparaDichiaratiPerAccertamento(def dichLiq) {

        dichLiq.each {

            it.residuoImposta = it.imposta ?: 0
            it.residuoImpostaAcconto = it.impostaAcconto ?: 0
            it.residuoImpostaLorda = it.impostaLorda ?: 0
            it.residuoMaggTARES = it.maggTARES ?: 0
            it.residuoRiferimenti = it.riferimenti
        }
    }

    def getPraticaAccTot(Long idPraticaRif) {
        def prt = PraticaTributo.createCriteria().list {
            eq("praticaTributoRif.id", idPraticaRif)
        }.toDTO(["contribuente.soggetto", "tipostato"])
    }

    /// Legge il valore attuale di FLAG_SANZ_MIN_RID di pratiche_tributo
    /// Nota : Questo valore viene gestito in automatico dai trigger
    ///        Dobbiamo leggerlo sempre da DB, saltando l'eventuale cache di Domain e/o DTO
    def getFlagSanzRidMinPratica(Long praticaId) {

        def filtri = [:]

        filtri << [ 'praticaId': (praticaId ?: 0)]

        String sql = """
			    SELECT PRTR.FLAG_SANZ_MIN_RID
			      FROM PRATICHE_TRIBUTO PRTR
			     WHERE PRTR.PRATICA = :praticaId
		"""

        def results = eseguiQuery(sql, filtri, null, true)

        String flagSanzRidMin = null

        results.each {
            flagSanzRidMin = it['FLAG_SANZ_MIN_RID'] as String
        }

        def sanzRidMin = ((flagSanzRidMin ?: 'N') == 'S')

        return sanzRidMin
    }

    def getSanzioni(long idPratica, short anno, String tipoTributo) {
        PraticaTributo.get(idPratica).sanzioniPratica.sort { it.sanzione.codSanzione }
    }

    def getTotaliSanzioni(long idPratica) {
        def listaTotSanz = SanzionePratica.createCriteria().list {
            projections {
                sum("importo")
                sum("abPrincipale")
                sum("rurali")
                sum("terreniComune")
                sum("terreniErariale")
                sum("areeComune")
                sum("areeErariale")
                sum("altriComune")
                sum("altriErariale")
                sum("fabbricatiDComune")
                sum("fabbricatiDErariale")
                sum("fabbricatiMerce")
            }
            eq("pratica.id", idPratica)
        }.collect { row ->
            [importoTotale    : row[0]
             , totAbPrincipale: row[1]
             , totRurali      : row[2]
             , totTerreniCom  : row[3]
             , totTerreniErar : row[4]
             , totAreeCom     : row[5]
             , totAreeErar    : row[6]
             , totAltriCom    : row[7]
             , totAltriErar   : row[8]
             , totFabbCom     : row[9]
             , totFabbErar    : row[10]
             , totFabbMerce   : row[11]
            ]
        }
        return listaTotSanz.flatten()
    }

    def hasRuoli(String tipoTributo, String codFiscale, long idOggetto, long idPratica) {
        def sql = """
            select count(*)
              from ruoli, oggetti_pratica, ruoli_oggetto
             where ruoli.ruolo = ruoli_oggetto.ruolo
               and oggetti_pratica.oggetto_pratica(+) = ruoli_oggetto.oggetto_pratica
               and ruoli.tipo_tributo = '${tipoTributo}'
               and ruoli_oggetto.cod_fiscale = '${codFiscale}'
               and (ruoli_oggetto.oggetto = ${idOggetto} or ruoli_oggetto.pratica = ${idPratica})
            """

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(sql)

        def nRuoli = 0
        sqlQuery.with {
            list()
        }.each {
            nRuoli = it
        }

        return (nRuoli > 0)
    }

    def calcoloImportoLordo(SanzionePraticaDTO sapr, String tipoTributo, boolean sanzioneMinimaSuRiduzione) {

        BigDecimal importoLordo = 0
        BigDecimal importoLordoRid = 0
        BigDecimal importoLordoRid2 = 0

        PraticaTributoDTO pratica = sapr.pratica
        SanzioneDTO sanz = sapr.sanzione

        BigDecimal riduzione = sapr.riduzione
        BigDecimal riduzione2 = sapr.riduzione2
        BigDecimal importo = sapr.importo ?: 0
        BigDecimal importoRid
        BigDecimal importoRid2

        if (riduzione) {
            importoRid = (((100.0 - riduzione) * importo) / 100.0).setScale(2, RoundingMode.HALF_UP)
            if (sanzioneMinimaSuRiduzione && sanz.sanzioneMinima) {
                if (importoRid < sanz.sanzioneMinima) {
                    importoRid = sanz.sanzioneMinima
                }
            }
        } else {
            importoRid = importo
        }

        if (riduzione2) {
            importoRid2 = (((100.0 - riduzione2) * importo) / 100.0).setScale(2, RoundingMode.HALF_UP)
            if (sanzioneMinimaSuRiduzione && sanz.sanzioneMinima) {
                if (importoRid2 < sanz.sanzioneMinima) {
                    importoRid2 = sanz.sanzioneMinima
                }
            }
        } else {
            importoRid2 = importo
        }

        importoLordo = importo
        importoLordoRid = importoRid
        importoLordoRid2 = importoRid2

        if (tipoTributo == 'TARSU') {

            List<CaricoTarsuDTO> carichiTarsu = OggettiCache.CARICHI_TARSU.valore
            CaricoTarsuDTO cata = carichiTarsu.find { it.anno == pratica.anno && it.flagLordo == 'S' }

            /// I Ravvedimenti su Versamento al momento non hanno oggetti_pratica, quindi applico sempre i CaTa
            def applicaCaTa = isRavvedimentoSuRuoli(pratica)

            if (!applicaCaTa) {
                def result = OggettoPratica.executeQuery("""
							select count(*) from OggettoPratica as ogpr
							where
								codiceTributo.flagRuolo = 'S' and  
								(pratica.praticaTributoRif.id = ${pratica.id} or 
									pratica.id = ${pratica.id})
							""")

                applicaCaTa = (result[0] > 0)
            }

            if (applicaCaTa &&
                    ((sapr.sanzione.codSanzione in [1, 100, 101]) ||
                            (sapr.sanzione.flagMaggTares == null && sapr.sanzione.tipoCausale == 'E')) && cata) {

                importoLordo = calcoloImportoLordoTarsu(importo, cata)
                importoLordoRid = calcoloImportoLordoTarsu(importoRid, cata)
                importoLordoRid2 = calcoloImportoLordoTarsu(importoRid2, cata)
            }
        }

        sapr.importoRidCalcolato = importoRid
        sapr.importoRid2Calcolato = importoRid2
        sapr.importoLordoCalcolato = importoLordo
        sapr.importoLordoRidCalcolato = importoLordoRid
        sapr.importoLordoRid2Calcolato = importoLordoRid2

        SanzionePratica sanzRaw = sapr.toDomain()
    }

    def calcoloImportoLordoTarsu(BigDecimal netto, CaricoTarsuDTO cata) {

        BigDecimal addEca = netto.multiply(cata.addizionaleEca ?: 0).divide(100.0).setScale(2, RoundingMode.HALF_UP)
        BigDecimal maggEca = netto.multiply(cata.maggiorazioneEca ?: 0).divide(100.0).setScale(2, RoundingMode.HALF_UP)
        BigDecimal addPro = netto.multiply(cata.addizionalePro ?: 0).divide(100.0).setScale(2, RoundingMode.HALF_UP)
        BigDecimal aliq = netto.multiply(cata.aliquota ?: 0).divide(100.0).setScale(2, RoundingMode.HALF_UP)

        BigDecimal lordo = netto.add(addEca).add(maggEca).add(addPro).add(aliq)

        return lordo
    }

    def getRuoliPratica(def pratica) {

        def sql = """
            select ruoli.ruolo "ruolo",
               decode(ruoli.tipo_ruolo, 1, 'P', 'S') "tipoRuolo",
               ruoli.tipo_tributo "tipoTributo",
               ruoli.anno_ruolo "annoRuolo",
               ruoli.anno_emissione "annoEmissione",
               ruoli.progr_emissione "progrEmissione",
               ruoli.data_emissione "dataEmissione",
               ruoli_oggetto.tributo "codiceTributo",
               ruoli.invio_consorzio "invioConsorzio",
               ruoli_oggetto.mesi_ruolo "mesiRuolo",
               ruoli_oggetto.importo "importo",
               sum(sgravi.importo) "sgravio",
               decode(ruoli.specie_ruolo, NULL, 'Ordinario', 'Coattivo') "specieRuolo",
               ruoli.importo_lordo "importoLordo",
               decode(ruoli.tipo_emissione,
                      'A',
                      'Acconto',
                      'S',
                      'Saldo',
                      'T',
                      'Totale',
                      'X',
                      '') "tipoEmissione"
          from ruoli, sgravi, oggetti_pratica, ruoli_oggetto
         where (ruoli_oggetto.ruolo = sgravi.ruolo(+))
           and (ruoli_oggetto.cod_fiscale = sgravi.cod_fiscale(+))
           and (ruoli_oggetto.sequenza = sgravi.sequenza(+))
           and (ruoli.ruolo = ruoli_oggetto.ruolo)
           and ruoli_oggetto.pratica = :pratica
           and (oggetti_pratica.oggetto_pratica(+) = ruoli_oggetto.oggetto_pratica)
         group by ruoli.ruolo,
                  ruoli.tipo_ruolo,
                  ruoli.tipo_emissione,
                  ruoli.tipo_tributo,
                  ruoli.anno_ruolo,
                  ruoli.anno_emissione,
                  ruoli.progr_emissione,
                  ruoli.data_emissione,
                  ruoli_oggetto.tributo,
                  ruoli.invio_consorzio,
                  ruoli_oggetto.mesi_ruolo,
                  ruoli_oggetto.giorni_ruolo,
                  ruoli_oggetto.importo,
                  ruoli.specie_ruolo,
                  ruoli_oggetto.cod_fiscale,
                  ruoli_oggetto.sequenza,
                  oggetti_pratica.pratica,
                  ruoli_oggetto.oggetto_pratica,
                  ruoli_oggetto.oggetto,
                  ruoli.importo_lordo
         order by ruoli.tipo_ruolo      asc,
                  ruoli.anno_ruolo      asc,
                  ruoli.anno_emissione  asc,
                  ruoli.progr_emissione asc,
                  ruoli_oggetto.tributo asc,
                  ruoli.data_emissione  asc,
                  ruoli.invio_consorzio asc
                """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {

            setLong('pratica', pratica)

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            list()
        }

        return results
    }

    def getRuoli(String tipoTributo, String codFiscale, Long idOggetto, long idPratica, def specieRuoli = [ORDINARIO: true, COATTIVO: true]) {

        if (!specieRuoli.any { k, v -> v }) {
            return []
        }

        def parametriQuery = [:]
        parametriQuery.pTipoTributo = tipoTributo
        parametriQuery.pCodFiscale = codFiscale
        // parametriQuery.pIdOggetto = idOggetto?.longValue()
        parametriQuery.pIdPratica = idPratica

        String sql = " 	FROM \
							RuoloOggetto AS ruOgg \
						INNER JOIN FETCH \
							ruOgg.ruolo as ruolo \
						INNER JOIN FETCH \
							ruOgg.ruoloContribuente as ruoloCtr \
					  	LEFT JOIN FETCH \
							ruOgg.oggetto as ogg \
						LEFT JOIN FETCH \
							ruOgg.pratica as prt \
						WHERE \
                            ruOgg.codFiscale = :pCodFiscale and \
							ruolo.tipoTributo.tipoTributo = :pTipoTributo and \
                            ruOgg.codFiscale = :pCodFiscale and \
							ruoloCtr.contribuente.codFiscale = :pCodFiscale and \
							prt.id = :pIdPratica \
        ORDER BY ruolo.tipoRuolo, ruolo.annoRuolo, ruolo.annoEmissione, ruolo.progrEmissione, ruOgg.codiceTributo.id, \
                 ruolo.dataEmissione , ruolo.invioConsorzio "

        def ruoli = RuoloOggetto.findAll(sql, parametriQuery).toDTO(["ruolo"])

        def specie = []
        if (specieRuoli.ORDINARIO) {
            specie << false
        }
        if (specieRuoli.COATTIVO) {
            specie << true
        }
        // Si filtra solo se è indicata una sola specie, altrimenti si restituisce l'elenco completo
        if (specie.size == 1) {
            ruoli = ruoli.findAll { it.ruolo.specieRuolo in specie }
        }

        ruoli.each {
            it.ruoloContribuente.totaleSgraviCalcolato = Sgravio.findAllByRuoloContribuente(it.ruoloContribuente.toDomain()).sum { s -> s.importo ?: 0 }
        }

        return ruoli
    }

    def getRuoliDenuncia(Long idPratica, Long idOggettoPratica, String tipoTributo, Long idOggetto, String codFiscale) {

        String sql = """
                SELECT RUOLI.RUOLO,
                   RUOLI.TIPO_RUOLO,
                   RUOLI.TIPO_TRIBUTO,
                   RUOLI.ANNO_RUOLO,
                   RUOLI.ANNO_EMISSIONE,
                   RUOLI.PROGR_EMISSIONE,
                   RUOLI.DATA_EMISSIONE,
                   RUOLI_OGGETTO.TRIBUTO,
                   RUOLI.INVIO_CONSORZIO,
                   RUOLI_OGGETTO.MESI_RUOLO,
                   RUOLI_OGGETTO.IMPORTO,
                   sum(SGRAVI.IMPORTO) sgravio,
                   RUOLI.SPECIE_RUOLO,
                   RUOLI_OGGETTO.COD_FISCALE,
                   RUOLI_OGGETTO.SEQUENZA,
                   OGGETTI_PRATICA.PRATICA,
                   RUOLI_OGGETTO.OGGETTO_PRATICA,
                   RUOLI_OGGETTO.OGGETTO,
                   decode(nvl(ruoli_oggetto.oggetto_pratica, 0),
                          0,
                          decode(nvl(ruoli_oggetto.pratica, 0),
                                 0,
                                 'N',
                                 decode(ruoli_oggetto.pratica, :p_pratica, 'S', 'N')),
                          decode(ruoli_oggetto.oggetto_pratica, :p_ogpr, 'S', 'N')) ruol_ogpr,
                   max(sequenza_sgravio) max_seq_sgra,
                   RUOLI.IMPORTO_LORDO,
                   RUOLI_OGGETTO.GIORNI_RUOLO,
                   max(ruoli.tipo_calcolo) tipo_calcolo,
                   RUOLI.TIPO_EMISSIONE,
                   max(ruoli.flag_depag) flag_depag
              FROM RUOLI, SGRAVI, OGGETTI_PRATICA, RUOLI_OGGETTO
             WHERE (ruoli_oggetto.ruolo = sgravi.ruolo(+))
               and (ruoli_oggetto.cod_fiscale = sgravi.cod_fiscale(+))
               and (ruoli_oggetto.sequenza = sgravi.sequenza(+))
               and (RUOLI.RUOLO = RUOLI_OGGETTO.RUOLO)
               and ((RUOLI.TIPO_TRIBUTO = :p_titr) AND
                   (RUOLI_OGGETTO.COD_FISCALE = :p_cod_fiscale) AND
                   (RUOLI_OGGETTO.OGGETTO = :p_ogge or
                   RUOLI_OGGETTO.PRATICA = :p_pratica) AND
                   (OGGETTI_PRATICA.OGGETTO_PRATICA(+) = RUOLI_OGGETTO.OGGETTO_PRATICA) AND
                   (:p_ogpr is not NULL))
             GROUP BY RUOLI.RUOLO,
                      RUOLI.TIPO_RUOLO,
                      RUOLI.TIPO_EMISSIONE,
                      RUOLI.TIPO_TRIBUTO,
                      RUOLI.ANNO_RUOLO,
                      RUOLI.ANNO_EMISSIONE,
                      RUOLI.PROGR_EMISSIONE,
                      RUOLI.DATA_EMISSIONE,
                      RUOLI_OGGETTO.TRIBUTO,
                      RUOLI.INVIO_CONSORZIO,
                      RUOLI_OGGETTO.MESI_RUOLO,
                      RUOLI_OGGETTO.GIORNI_RUOLO,
                      RUOLI_OGGETTO.IMPORTO,
                      RUOLI.SPECIE_RUOLO,
                      RUOLI_OGGETTO.COD_FISCALE,
                      RUOLI_OGGETTO.SEQUENZA,
                      OGGETTI_PRATICA.PRATICA,
                      RUOLI_OGGETTO.OGGETTO_PRATICA,
                      RUOLI_OGGETTO.OGGETTO,
                      decode(nvl(ruoli_oggetto.oggetto_pratica, 0),
                             0,
                             decode(nvl(ruoli_oggetto.pratica, 0),
                                    0,
                                    'N',
                                    decode(ruoli_oggetto.pratica, :p_pratica, 'S', 'N')),
                             decode(ruoli_oggetto.oggetto_pratica, :p_ogpr, 'S', 'N')),
                      RUOLI.IMPORTO_LORDO
             ORDER BY RUOLI.TIPO_RUOLO      ASC,
                      RUOLI.ANNO_RUOLO      ASC,
                      RUOLI.ANNO_EMISSIONE  ASC,
                      RUOLI.PROGR_EMISSIONE ASC,
                      RUOLI_OGGETTO.TRIBUTO ASC,
                      RUOLI.DATA_EMISSIONE  ASC,
                      RUOLI.INVIO_CONSORZIO ASC
                     """

        // Utilizzo la replace perché con il set dei parametri la query non viene costruita correttamente
        sql = sql.replace(":p_pratica", idPratica as String)
        sql = sql.replace(":p_ogpr", idOggettoPratica as String)
        sql = sql.replace(":p_titr", "'${tipoTributo}'")
        sql = sql.replace(":p_cod_fiscale", "'${codFiscale}'")
        sql = sql.replace(":p_ogge", idOggetto as String)

        return sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }.collect {
            [
                    ruolo            :
                            [
                                    tipoRuolo     : it.tipoRuolo == 1 ? 'P' : 'S',
                                    annoRuolo     : it.annoRuolo,
                                    annoEmissione : it.annoEmissione,
                                    progrEmissione: it.progrEmissione,
                                    datEmissione  : it.dataEmissione,
                                    invioConsorzio: it.invioConsorzio,
                                    specieRuolo   : it.specieRuolo ? 'Coattivo' : 'Ordinario',
                                    tipoEmissione : tipoEmissione[it.tipoEmissione],
                                    id            : it.ruolo,
                                    mesiRuolo     : it.mesiRuolo,
                                    giorniRuolo   : it.giorniRuolo,
                                    dataEmissione : it.dataEmissione
                            ],
                    codiceTributo    : [
                            id: it.tributo,
                    ],
                    importo          : it.importo,
                    importoLordo     : it.importoLordo,
                    ruoloContribuente: [
                            totaleSgravi: it.sgravio
                    ],
                    ruoloOggetto     : [
                            sequenza: it.sequenza
                    ]
            ]
        }
    }

    def getPraticheRifAccTot(long idPratica) {

        def filtri = [:]

        filtri << ['p_pratica': idPratica]

        String sql = """
				SELECT
					PRTR.PRATICA,
					PRTR.TIPO_TRIBUTO,
					PRTR.TIPO_PRATICA,
					PRTR.TIPO_EVENTO,
					PRTR.FLAG_DENUNCIA,
					PRTR.STATO_ACCERTAMENTO,
					PRTR.ANNO,
					PRTR.DATA,
					PRTR.NUMERO,
					PRTR.DATA_NOTIFICA,
					f_importo_acc_lordo(PRTR.PRATICA,'N') IMPORTO_TOTALE,
					f_importo_acc_lordo(PRTR.PRATICA,'S') IMPORTO_RIDOTTO,
					f_importo_acc_lordo(PRTR.PRATICA,'S') IMPORTO_RIDOTTO_2 ,
					PRTR.MOTIVO
				FROM
					PRATICHE_TRIBUTO PRTR
				WHERE
					PRTR.PRATICA_RIF = :p_pratica
				ORDER BY
					PRTR.DATA,
					LPAD(PRTR.NUMERO,15,' '),
					PRTR.PRATICA
		"""

        def params = [
                max       : Integer.MAX_VALUE,
                activePage: 0,
                offset    : 0,
        ]
        def elenco = eseguiQuery("${sql}", filtri, params)

        def praticheRif = []

        elenco.each { row ->

            def praticaRif = [:]

            praticaRif.id = row['PRATICA'] as Long
            praticaRif.tipoTributo = row['TIPO_TRIBUTO']
            praticaRif.tipoPratica = row['TIPO_PRATICA']
            praticaRif.tipoEvento = row['TIPO_EVENTO']
            praticaRif.flagDenuncia = row['FLAG_DENUNCIA']
            praticaRif.statoAccertamento = row['STATO_ACCERTAMENTO']
            praticaRif.anno = row['ANNO'] as Short
            praticaRif.data = row['DATA']
            praticaRif.numero = row['NUMERO']
            praticaRif.dataNotifica = row['DATA_NOTIFICA']
            praticaRif.importoTotale = row['IMPORTO_TOTALE'] as BigDecimal
            praticaRif.importoRidotto = row['IMPORTO_RIDOTTO'] as BigDecimal
            praticaRif.importoRidotto2 = row['IMPORTO_RIDOTTO_2'] as BigDecimal
            praticaRif.motivo = row['MOTIVO'] as String

            praticheRif << praticaRif
        }

        return praticheRif
    }

    def getPraticheRif(long idPratica) {
        def lista = PraticaTributo.createCriteria().list {

            eq("praticaTributoRif.id", idPratica)

            order("data", "asc")
            order("numero", "asc")
            order("id", "asc")
        }.toDTO()
    }

    def getDescrizioneTipoPratica(String tipoPratica, String tipoTributo, Long anno) {
        return tipiPratica[tipoPratica] + ' ' + imposteService.getDescrizioneTitr(anno, tipoTributo)
    }

    def getVersContTribAnno(String codFiscale, String tipoTributo, Integer anno) {

        def parametriQuery = [:]

        parametriQuery.pCodFiscale = codFiscale ?: '-'
        parametriQuery.pAnno = (short) (anno ?: 0)
        parametriQuery.pTipoTributo = tipoTributo ?: '-'

        String sql = """
                    select new Map(
                        SUM(vers.importoVersato) AS versato,
						MAX(vers.fabbricati) AS fabbricati
						)
                    FROM
                        Versamento AS vers
                    WHERE
                        vers.pratica.id IS NULL AND
						vers.contribuente.codFiscale = :pCodFiscale AND
						vers.tipoTributo.tipoTributo = :pTipoTributo AND
						vers.anno = :pAnno
                    """

        def lista = PraticaTributo.executeQuery(sql, parametriQuery)

        return lista.get(0)
    }

    def caricaListaStati(FiltroRicercaViolazioni parametri) {

        String where = ""
        String extraTables = ""

        def filtri = [:]

        String tipoPratica = parametri.tipoPratica
        String tipiPratica

        filtri << ['tipoTributo': parametri.tipoTributo]
        if (tipoPratica == '*') {
            tipiPratica = "'A', 'L'"
        } else {
            tipiPratica = "'${tipoPratica}'"
        }

        def whereARuolo = ""
        if (parametri.aRuolo != 'T') {
            where += """ and (
                    (:aRuolo = 'S' and exists (select 1
                        from ruoli_contribuente ruco
                            where ruco.pratica = prtr.pratica)) or
                     (:aRuolo = 'N' and not exists (select 1
                        from ruoli_contribuente ruco
                            where ruco.pratica = prtr.pratica)))"""

            filtri << ['aRuolo': parametri.aRuolo]
        }

        if (parametri.inviatoPagoPa in ["S", "N"]) {
            filtri << ['inviatoPagoPa': parametri.inviatoPagoPa]
            where += " AND nvl(prtr.flag_depag,'N') = :inviatoPagoPa "
        }

        where += " AND ${speseNotificaOnPraticaSqlClause(parametri.conSpeseNotifica)}"

        if (parametri.cognome) {
            filtri << ['cognome': parametri.cognome.toUpperCase()]
            where += " AND UPPER(SOGG.COGNOME) LIKE :cognome "
        }
        if (parametri.nome) {
            filtri << ['nome': parametri.nome.toUpperCase()]
            where += " AND UPPER(SOGG.NOME) LIKE :nome "
        }
        if (parametri.cf) {
            filtri << ['codFiscale': parametri.cf.toUpperCase()]
            where += " AND UPPER(CONT.COD_FISCALE) LIKE :codFiscale "
        }
        if (parametri.numeroIndividuale) {
            filtri << ['numeroIndividuale': parametri.numeroIndividuale as Long]
            where += " AND SOGG.NI = :numeroIndividuale "
        }
        if (parametri.codContribuente) {
            filtri << ['codContribuente': parametri.codContribuente as Integer]
            where += " AND CONT.COD_CONTRIBUENTE = :codContribuente "
        }

        if (parametri.daAnno) {
            filtri << ['daAnno': parametri.daAnno as Short]
            where += " AND PRTR.ANNO(+) >= :daAnno "
        }
        if (parametri.aAnno) {
            filtri << ['aAnno': parametri.aAnno as Short]
            where += " AND PRTR.ANNO(+) <= :aAnno "
        }
        if (parametri.daData) {
            filtri << ['daData': parametri.daData]
            where += " AND PRTR.DATA >= :daData "
        }
        if (parametri.aData) {
            filtri << ['aData': parametri.aData]
            where += " AND PRTR.DATA <= :aData "
        }

        // Residente
        if (parametri?.residente == "S") {
            where += " and (sogg.tipo_residente = 0 and sogg.fascia = 1) "
        } else if (parametri?.residente == "N") {
            where += " and (sogg.tipo_residente = 1 or (sogg.tipo_residente = 0 and (sogg.fascia != 1 or sogg.fascia is null))) "
        }

        // Numero
        def daNumero = parametri?.daNumeroPratica
        def aNumero = parametri?.aNumeroPratica
        def isDaNumeroNotEmpty = daNumero != null && daNumero != ""
        def isANumeroNotEmpty = aNumero != null && aNumero != ""

        if (isDaNumeroNotEmpty) {
            if (daNumero.contains('%')) {
                where += " and upper(prtr.numero) like :daNumeroPratica "
                filtri << ['daNumeroPratica': daNumero.toUpperCase()]
            } else {
                where += " and lpad(upper(prtr.numero), 15, ' ') >= :daNumeroPratica "
                filtri << ['daNumeroPratica': daNumero.padLeft(15).toUpperCase()]
            }
        }

        if (isANumeroNotEmpty) {
            if (!isDaNumeroNotEmpty || (isDaNumeroNotEmpty && !daNumero.contains('%'))) {
                where += " and lpad(prtr.numero, 15, ' ') <= :aNumeroPratica "
                filtri << ['aNumeroPratica': aNumero.padLeft(15).toUpperCase()]
            }
        }

        // daDataRifRavv è definito solo per i Ravvedimenti
        if (parametri.tipoPratica == TipoPratica.V.tipoPratica) {
            if (parametri.daDataRifRavv) {
                filtri << ['daDataRifRavv': parametri.daDataRifRavv.format('dd/MM/yyyy')]
                where += " AND PRTR.DATA_RIF_RAVVEDIMENTO >= TO_DATE(:daDataRifRavv, 'dd/mm/yyyy') "
            }
            if (parametri.aDataRifRavv) {
                filtri << ['aDataRifRavv': parametri.aDataRifRavv.format('dd/MM/yyyy')]
                where += " AND PRTR.DATA_RIF_RAVVEDIMENTO <= TO_DATE(:aDataRifRavv, 'dd/mm/yyyy') "
            }
        }

        if (parametri.tipoNotifica) {
            filtri << ['tipoNotifica': parametri.tipoNotifica.tipoNotifica]
            where += " AND PRTR.TIPO_NOTIFICA = :tipoNotifica "
        }
        if (parametri.daDataNotifica) {
            filtri << ['daDataNotifica': parametri.daDataNotifica]
            where += " AND PRTR.DATA_NOTIFICA >= :daDataNotifica "
        }
        if (parametri.aDataNotifica) {
            filtri << ['aDataNotifica': parametri.aDataNotifica]
            where += " AND PRTR.DATA_NOTIFICA <= :aDataNotifica "
        }
        if (parametri.nessunaDataNotifica) {
            where += " AND PRTR.DATA_NOTIFICA IS NULL "
        }

        if (parametri.daImporto) {
            filtri << ['daImporto': parametri.daImporto]
            where += " AND NVL(PRTR.IMPORTO_TOTALE, 0) >= :daImporto "
        }
        if (parametri.aImporto) {
            filtri << ['aImporto': parametri.aImporto]
            where += " AND NVL(PRTR.IMPORTO_TOTALE, 0) <= :aImporto "
        }
        if ((parametri.daDataPagamento) || (parametri.aDataPagamento)) {
            where += " AND EXISTS (SELECT COD_FISCALE FROM VERSAMENTI VERS WHERE PRTR.PRATICA = VERS.PRATICA "
            if (parametri.daDataPagamento) {
                filtri << ['daDataPagamento': parametri.daDataPagamento]
                where += " AND VERS.DATA_PAGAMENTO >= :daDataPagamento "
            }
            if (parametri.aDataPagamento) {
                filtri << ['aDataPagamento': parametri.aDataPagamento]
                where += " AND VERS.DATA_PAGAMENTO <= :aDataPagamento "
            }
            where += ") "
        }

        def tipiAttoRateizzato = parametri.tipiAttoSelezionati.collect { t -> t.tipoAtto }.findAll { it == 90 }.size() ?: 0
        if (tipiAttoRateizzato) {
            if (parametri.tipologiaRate) {
                filtri << ['tipologiaRate': parametri.tipologiaRate.toUpperCase()]
                where += " AND NVL(PRTR.TIPOLOGIA_RATE,'N') LIKE :tipologiaRate "
            }
            if (parametri.daImportoRateizzato) {
                filtri << ['daImportoRateizzato': parametri.daImportoRateizzato as Double]
                where += " AND (PRTR.IMPORTO_TOTALE + NVL(PRTR.MORA,0) - NVL(PRTR.VERSATO_PRE_RATE,0)) >= :daImportoRateizzato "
            }
            if (parametri.aImportoRateizzato) {
                filtri << ['aImportoRateizzato': parametri.aImportoRateizzato as Double]
                where += " AND (PRTR.IMPORTO_TOTALE + NVL(PRTR.MORA,0) - NVL(PRTR.VERSATO_PRE_RATE,0)) <= :aImportoRateizzato "
            }
            if (parametri.daDataRateazione) {
                filtri << ['daDataRateazione': parametri.daDataRateazione]
                where += " AND PRTR.DATA_RATEAZIONE >= :daDataRateazione "
            }
            if (parametri.aDataRateazione) {
                filtri << ['aDataRateazione': parametri.aDataRateazione]
                where += " AND PRTR.DATA_RATEAZIONE <= :aDataRateazione "
            }
        }

        String whereStampe = ""

        if (parametri.daDataStampa) {
            filtri << ['daDataStampa': parametri.daDataStampa]
            if (parametri.aDataStampa) {
                filtri << ['aDataStampa': parametri.aDataStampa]
                whereStampe += "f_data_stampa(PRTR.PRATICA) BETWEEN :daDataStampa AND :aDataStampa"
            } else {
                whereStampe += "f_data_stampa(PRTR.PRATICA) >= :daDataStampa"
            }
        } else {
            if (parametri.aDataStampa) {
                filtri << ['aDataStampa': parametri.aDataStampa]
                whereStampe += "f_data_stampa(PRTR.PRATICA) <= :aDataStampa"
            }
        }
        if (parametri.daStampare) {
            where += " AND ((f_data_stampa(PRTR.PRATICA) IS NULL) "
            if (!whereStampe.isEmpty()) {
                where += "OR (${whereStampe}) "
            }
            where += ") "
        } else {
            if (!whereStampe.isEmpty()) {
                where += " AND ${whereStampe} "
            }
        }

        String condizione
        String listaTipi

        if (!parametri.tuttiTipiStatoSelezionati) {

            def lista = parametri.tipiStatoSelezionati.collect { t -> t.tipoStato }
            HashSet<String> hs = new HashSet<String>(lista)

            condizione = ""
            listaTipi = ""
            hs.each { tipo ->
                if (!tipo) {
                    condizione += "PRTR.STATO_ACCERTAMENTO IS NULL "
                } else {
                    listaTipi += "'" + tipo + "',"
                }
            }
            listaTipi = (listaTipi) ? listaTipi.substring(0, listaTipi.size() - 1) : ""
            if (condizione != "" && listaTipi != "") {
                condizione += " OR PRTR.STATO_ACCERTAMENTO IN (" + listaTipi + ") "
            }
            if (condizione == "" && listaTipi != "") {
                condizione += " PRTR.STATO_ACCERTAMENTO IN (" + listaTipi + ") "
            }
            if (condizione) {
                where += """ AND (${condizione}) """
            }
        }

        if (!parametri.tuttiTipiAttoSelezionati) {

            def lista = parametri.tipiAttoSelezionati.collect { t -> t.tipoAtto }
            HashSet<String> hs = new HashSet<String>(lista)

            condizione = ""
            listaTipi = ""
            hs.each { tipo ->
                if (!tipo) {
                    condizione += " PRTR.TIPO_ATTO IS NULL "
                } else {
                    listaTipi += "'" + tipo + "',"
                }
            }
            listaTipi = (listaTipi) ? listaTipi.substring(0, listaTipi.size() - 1) : ""
            if (condizione != "" && listaTipi != "") {
                condizione += " OR  PRTR.TIPO_ATTO IN (" + listaTipi + ") "
            }
            if (condizione == "" && listaTipi != "") {
                condizione += " PRTR.TIPO_ATTO IN (" + listaTipi + ") "
            }
            if (condizione) {
                where += """ AND (${condizione}) """
            }
        }

        String sqlImporti = ""

        if (tipoPratica in [TipoPratica.A.tipoPratica, TipoPratica.S.tipoPratica, TipoPratica.V.tipoPratica]) {
            sqlImporti = """
						SUM(f_importo_acc_lordo(PRTR.PRATICA,'N')) AS IMPORTO_TOTALE,
						SUM(f_importo_acc_lordo(PRTR.PRATICA,'S')) AS IMPORTO_RIDOTTO,
						0 AS IMPORTO_RATEIZZATO,
						SUM(PRTR.IMPORTO_TOTALE) AS IMPORTO_TOT_NETTO,
						SUM(PRTR.IMPORTO_RIDOTTO) AS IMPORTO_RID_NETTO,
			"""
            where += """
						AND ((PRTR.PRATICA_RIF IS NULL) OR
							 (PRTR.PRATICA_RIF IS NOT NULL AND
							 SUBSTR(f_pratica(PRTR.PRATICA_RIF), 1, 1) <> 'A'))
			"""
        } else if (tipoPratica == '*') {
            sqlImporti = """
						SUM(PRTR.IMPORTO_TOTALE) AS IMPORTO_TOTALE,
						SUM(PRTR.IMPORTO_RIDOTTO) AS IMPORTO_RIDOTTO,
						SUM(PRTR.IMPORTO_TOTALE + NVL(PRTR.MORA,0) - NVL(PRTR.VERSATO_PRE_RATE,0)) AS IMPORTO_RATEIZZATO,
						0 AS IMPORTO_TOT_NETTO,
						0 AS IMPORTO_RID_NETTO,
			"""
        } else {
            sqlImporti = """
						SUM(PRTR.IMPORTO_TOTALE) AS IMPORTO_TOTALE,
						SUM(PRTR.IMPORTO_RIDOTTO) AS IMPORTO_RIDOTTO,
						0 AS IMPORTO_RATEIZZATO,
						0 AS IMPORTO_TOT_NETTO,
						0 AS IMPORTO_RID_NETTO,
			"""
        }

        String sql = """
				SELECT  NVL(PRTR.STATO_ACCERTAMENTO,'-') AS CODSTATO,
				        NVL(TIST.DESCRIZIONE,'') AS DESCRSTATO,
				        NVL(TIST.NUM_ORDINE,DECODE(NVL(PRTR.STATO_ACCERTAMENTO,'-'),'-',-1,9999)) AS ORDINESTATO,
				        NVL(PRTR.TIPO_ATTO,0) AS CODTIPOATTO,
				        NVL(TIAT.DESCRIZIONE,'') AS DESCRTIPOATTO,
						COUNT(PRTR.PRATICA) NUMERO_PRATICHE,
						SUM(CASE WHEN PRTR.DATA_NOTIFICA IS NOT NULL THEN 1 ELSE 0 END) AS NOTIFICATE,
						SUM(CASE WHEN PRTR.DATA_NOTIFICA IS NULL THEN 1 ELSE 0 END) AS NON_NOTIFICATE,
						SUM(CASE WHEN PRTR.NUMERO IS NOT NULL THEN 1 ELSE 0 END) AS NUMERATE,
						SUM(CASE WHEN PRTR.NUMERO IS NULL THEN 1 ELSE 0 END) AS NON_NUMERATE,
						${sqlImporti}
						SUM((SELECT NVL(SUM(VERS.IMPORTO_VERSATO), 0)
								FROM VERSAMENTI VERS
								WHERE VERS.TIPO_TRIBUTO = PRTR.TIPO_TRIBUTO
								AND VERS.PRATICA = PRTR.PRATICA)) AS IMPORTO_VERSATO,
						SUM((SELECT NVL(SUM(VERS.IMPORTO_VERSATO), 0)
								FROM VERSAMENTI VERS
								WHERE VERS.TIPO_TRIBUTO = PRTR.TIPO_TRIBUTO
								AND VERS.PRATICA = PRTR.PRATICA
								AND VERS.RATA BETWEEN 1 AND PRTR.RATE)) AS VERSATO_RATE
				FROM	PRATICHE_TRIBUTO PRTR,
						CONTRIBUENTI CONT,
						SOGGETTI SOGG,
						TIPI_STATO TIST,
						TIPI_ATTO TIAT,
                        RAPPORTI_TRIBUTO RATR
						${extraTables}
				WHERE	PRTR.TIPO_TRIBUTO = :tipoTributo AND
						PRTR.TIPO_PRATICA IN (${tipiPratica}) AND
						CONT.COD_FISCALE = PRTR.COD_FISCALE AND
						SOGG.NI = CONT.NI AND
						PRTR.STATO_ACCERTAMENTO = TIST.TIPO_STATO(+) AND
						PRTR.TIPO_ATTO = TIAT.TIPO_ATTO(+) AND
						PRTR.PRATICA = RATR.PRATICA
						${where}
				GROUP BY
						PRTR.STATO_ACCERTAMENTO,
						TIST.DESCRIZIONE,
						TIST.NUM_ORDINE,
						PRTR.TIPO_ATTO,
						TIAT.DESCRIZIONE
		"""

        def params = [
                max       : Integer.MAX_VALUE,
                activePage: 0,
                offset    : 0,
        ]
        def elenco = eseguiQuery("${sql}", filtri, params)

        def perTipoAtto = []
        String codStato
        String codTipoAtto
        String ordineStato
        String sorter

        elenco.each { row ->

            def elemento = [:]

            codStato = row['CODSTATO'] as String
            codTipoAtto = row['CODTIPOATTO'] as String
            ordineStato = row['ORDINESTATO'] as String

            elemento.id = codStato + "_" + codTipoAtto

            elemento.codStato = codStato
            elemento.codTipoAtto = codTipoAtto
            elemento.descrStato = row['DESCRSTATO'] as String
            elemento.descrTipoAtto = row['DESCRTIPOATTO'] as String
            elemento.numeroPratiche = row['NUMERO_PRATICHE'] as Long
            elemento.notificate = row['NOTIFICATE'] as Long
            elemento.nonNotificate = row['NON_NOTIFICATE'] as Long
            elemento.numerate = row['NUMERATE'] as Long
            elemento.nonNumerate = row['NON_NUMERATE'] as Long

            elemento.importoTotale = row['IMPORTO_TOTALE'] as BigDecimal
            elemento.importoRidotto = row['IMPORTO_RIDOTTO'] as BigDecimal

            elemento.importoRateizzato = row['IMPORTO_RATEIZZATO'] as BigDecimal

            elemento.importoTotNetto = row['IMPORTO_TOT_NETTO'] as BigDecimal
            elemento.importoRidNetto = row['IMPORTO_RID_NETTO'] as BigDecimal

            elemento.importoVersato = row['IMPORTO_VERSATO'] as BigDecimal
            elemento.versatoRate = row['VERSATO_RATE'] as BigDecimal

            if (elemento.descrTipoAtto) {
                elemento.descrTipoAtto = elemento.codTipoAtto + " - " + row['DESCRTIPOATTO'] as String
            }

            elemento.sorter = (String.format("%5s", ordineStato) + codStato + String.format("%2s", codTipoAtto)).replace(' ', '0')

            perTipoAtto << elemento
        }
        perTipoAtto.sort { it.sorter }

        def catalogo = []

        String codStatoOld = ''
        Integer tipoRiga = 0

        perTipoAtto.each {

            if (it.codStato != codStatoOld) {

                def stato = [:]

                codStato = it.codStato

                stato.id = codStato
                stato.tipoRiga = tipoRiga
                /// Utilizzato per tematizzare le righe pari/dispari della griglia di selezione

                stato.codStato = codStato
                stato.descrStato = it.descrStato

                def tipiAtto = perTipoAtto.findAll { it.codStato == codStato }

                stato.notificate = tipiAtto.sum { it.notificate }
                stato.nonNotificate = tipiAtto.sum { it.nonNotificate }
                stato.numerate = tipiAtto.sum { it.numerate }
                stato.nonNumerate = tipiAtto.sum { it.nonNumerate }

                stato.numeroPratiche = tipiAtto.sum { it.numeroPratiche ?: 0 }

                stato.importoTotale = tipiAtto.sum { it.importoTotale ?: 0 }
                stato.importoRidotto = tipiAtto.sum { it.importoRidotto ?: 0 }

                stato.importoRateizzato = tipiAtto.sum { it.importoRateizzato ?: 0 }

                stato.importoTotNetto = tipiAtto.sum { it.importoTotNetto ?: 0 }
                stato.importoRidNetto = tipiAtto.sum { it.importoRidNetto ?: 0 }

                stato.importoAddEca = tipiAtto.sum { it.importoAddEca ?: 0 }
                stato.importoMagEca = tipiAtto.sum { it.importoMagEca ?: 0 }
                stato.importoAddPro = tipiAtto.sum { it.importoAddPro ?: 0 }

                stato.importoInteressi = tipiAtto.sum { it.importoInteressi ?: 0 }
                stato.importoSanzioni = tipiAtto.sum { it.importoSanzioni ?: 0 }

                stato.importoVersato = tipiAtto.sum { it.importoVersato ?: 0 }
                stato.versatoRate = tipiAtto.sum { it.versatoRate ?: 0 }

                stato.tipiAtto = tipiAtto

                catalogo << stato

                if (++tipoRiga >= 2) tipoRiga = 0

                codStatoOld = codStato
            }
        }

        return catalogo
    }

    private speseNotificaOnPraticaSqlClause(def conSpeseNotificaFilter) {
        if (!(conSpeseNotificaFilter in ["S", "N"])) {
            return " 1 = 1 "
        }
        return """
            ${conSpeseNotificaFilter == 'S' ? 'EXISTS' : 'NOT EXISTS'} (
                select 1
                  from sanzioni_pratica sapr, sanzioni sanz
                 where sapr.tipo_tributo = sanz.tipo_tributo
                   and sapr.cod_sanzione = sanz.cod_sanzione
                   and sapr.sequenza_sanz = sanz.sequenza
                   and sanz.tipo_causale = 'S'
                   and sapr.pratica = prtr.pratica
            ) 
        """
    }

    def caricaLiquidazioni(def params, def filtri, def sortBy = null, def soloId = false) {

        def output

        def execTime = commonService.timeMe {

            def mappaFiltri = creaFiltriLiquidazioni(filtri)

            def sortBySql = ""

            def whereRate = """
                            and (select nvl(count(*), 0)
                                from rate_pratica rtpr
                                where rtpr.pratica = prtr.pratica)
                        """

            switch (filtri.rateizzate.conRate) {
                case 'T':
                    whereRate = ''
                    break
                case 'S':
                    whereRate += " > 0"
                    break
                case 'N':
                    whereRate += " = 0"
            }

            String filtroDaDataStampa = ""
            String filtroADataStampa = ""
            String filtroDaStampare = ""

            if (filtri.daDataStampa) {
                mappaFiltri << ['daDataStampa': filtri.daDataStampa]
                filtroDaDataStampa = """ "dataStampa" >= :daDataStampa """
            }
            if (filtri.aDataStampa) {
                mappaFiltri << ['aDataStampa': filtri.aDataStampa]
                filtroADataStampa = """ and "dataStampa" <= :aDataStampa """
            }
            def filtroDataStampa = """
            ${filtroDaDataStampa.replaceAll('\n', '').isEmpty() ? ' 1 = 1 ' : filtroDaDataStampa}
            ${filtroADataStampa.replaceAll('\n', '').isEmpty() ? ' AND 1 = 1 ' : filtroADataStampa}
        """

            if (filtri.daStampare) {
                filtroDaStampare = ((filtroDaDataStampa.replace("\n", '').isEmpty() && filtroADataStampa.replace("\n", '').isEmpty()) ?
                        " AND " : " OR ") + filtroDaStampare + """ "dataStampa" is null """
            }

            def whereStampa = """
            where 
            (${filtroDataStampa})
            ${filtroDaStampare}
        """

            sortBy.each { k, v ->
                if (v.verso) {
                    // Esiste almeno un campo si crea la stringa Order By
                    if (sortBySql.isEmpty()) {
                        sortBySql += "Order By\n"
                    }

                    switch (k) {
                        case 'codFiscale':
                            sortBySql += """\nlpad(upper("codFiscale"), 15, \' \') ${v.verso},"""
                            break
                        default:
                            sortBySql += """\n"$k" ${v.verso},"""
                            break
                    }
                }
            }

            def tributiPraticheFiltro = creaFiltriTipoTributoEPratica(filtri)

            sortBySql = !sortBySql.isEmpty() ? sortBySql.substring(0, sortBySql.length() - 1) : ""


            def whereRuolo = ""
            def fromRuolo = ""

            if (filtri.aRuolo && filtri.aRuolo != "T") {
                whereRuolo += """ 
                            and ruoli.ruolo = sapr.ruolo 
                            and prtr.pratica = sapr.pratica
                            and sapr.ruolo ${filtri.aRuolo == "S" ? " IS NOT NULL " : " IS NULL "}
                          """
                fromRuolo += """ ruoli ruoli, 
                             sanzioni_pratica sapr,
                         """
            }

            def sql = """
        SELECT * from (
                select
                   prtr.note "note",
                   prtr.motivo "motivo",
                   prtr.flag_depag "flagDePag",
                   upper(translate (soggetti.cognome_nome, '/', ' ')) "contribuente",
                   soggetti.fascia "fascia",
                   soggetti.tipo_residente "tipoResidente",
                   prtr.tipo_tributo "tipoTributo",
                   soggetti.ni "numeroIndividuale",
                   contribuenti.cod_fiscale "codFiscale",
                   f_round(prtr.importo_ridotto, 1) "importoRidotto",
                   prtr.data_notifica "dataNotifica",
                   prtr.tipo_notifica "tipoNotifica",
                   prtr.data_rateazione "dataRateazione",
                   tist.descrizione "statoAccertamento",
                   prtr.anno "anno",
                   lpad(prtr.numero, 15) "clNumero",
                   prtr.pratica "pratica",
                   prtr.pratica "id",
                   prtr.data "data",
                   vers.data_pagam "dataPag",
                    DECODE(VERS_MULTI.DATA_PAGAM,NULL,NULL,TO_CHAR(VERS_MULTI.DATA_PAGAM,'DD/mm/yyyy')) "dataPagamento",
                    NVL(VERS_MULTI.NUM_VERS,0) "versamentiMultipli",
                     CASE WHEN VERS_MULTI.num_vers != vers.num_vers_filtrati THEN 'S' ELSE 'N' END AS "versatoParziale",
                   vers.imp_versato "impVer",
                   nvl(prtr.versato_pre_rate, 0) as "versatoPreRate",
                   f_round(prtr.imposta_totale, 1) "impC",
                   (select sum(sapr.importo)
                        from sanzioni_pratica sapr, sanzioni sanz
                       where sapr.pratica = prtr.pratica
                        and sapr.tipo_tributo = sanz.tipo_tributo
                       and sapr.cod_sanzione = sanz.cod_sanzione
                       and sapr.sequenza_sanz = sanz.sequenza
                       and sanz.flag_imposta is null
                       and nvl(sanz.tipo_causale, 'X') = 'I') "totInteressi", 
                   (select sum(sapr.importo)
                       from sanzioni_pratica sapr, sanzioni sanz
                      where sapr.pratica = prtr.pratica
                       and sapr.tipo_tributo = sanz.tipo_tributo
                       and sapr.cod_sanzione = sanz.cod_sanzione
                       and sapr.sequenza_sanz = sanz.sequenza
                       and sanz.flag_imposta is null
                       and nvl(sanz.tipo_causale, 'X') in ('O', 'P', 'T')) "totSanzioni",
                   f_round(prtr.importo_totale, 1) "impTot",
                   upper(soggetti.cognome) "cognome",
                   upper(soggetti.nome) "nome",
                   prtr.tipo_pratica "tipoPratica",
                   prtr.tipo_evento "tipoEvento",
                   ratr.tipo_rapporto "tipoRapporto",
                   (select sum(sapr.importo)
                      from sanzioni_pratica sapr, sanzioni sanz
                     where sapr.cod_sanzione = sanz.cod_sanzione
                       and sapr.sequenza_sanz = sanz.sequenza
                       and sapr.tipo_tributo = sanz.tipo_tributo
                       and sanz.tipo_causale = 'S'
                       and sapr.pratica = prtr.pratica) "speseNotifica",
                   to_number(decode(f_vers_cont_liq(prtr.anno,
                                                    contribuenti.cod_fiscale,
                                                    prtr.data,
                                                    prtr.tipo_tributo),
                                    0,
                                    null,
                                    f_vers_cont_liq(prtr.anno,
                                                    contribuenti.cod_fiscale,
                                                    prtr.data,
                    prtr.tipo_tributo))) "versamenti",
                   prtr.tipo_atto "tipoAtto",
                   (select max(1)
                      from rate_pratica rtpr
                     where rtpr.pratica = prtr.pratica) "presenzaRate",
                    coen.presso "nominativoPresso",
                    coen.indirizzo "indirizzo",
                    coen.comune_provincia "comuneProvincia",
                    coen.cap "cap",
                    prtr.importo_totale + nvl(prtr.mora, 0) -
                   nvl(prtr.versato_pre_rate, 0) "importoRateizzato",
                   decode(nvl(prtr.rate, 0),
                          0,
                          0,
                          round(prtr.importo_rate * prtr.rate, 2) -
                          (prtr.importo_totale + nvl(prtr.mora, 0) -
                           nvl(prtr.versato_pre_rate, 0))) "importoInteressi",
                   decode(nvl(prtr.rate, 0),
                          0,
                          prtr.importo_totale + nvl(prtr.mora, 0) -
                          nvl(prtr.versato_pre_rate, 0),
                          round((select sum(sapr.importo)
                              from sanzioni_pratica sapr
                             where sapr.pratica = prtr.pratica),
                            2)) "importoDovuto",
                   (select nvl(sum(importo_versato), 0)
                      from versamenti vers
                     where vers.tipo_tributo = prtr.tipo_tributo
                       and vers.pratica = prtr.pratica
                       and vers.rata between 1 and prtr.rate) "versato",
                   prtr.tipologia_rate "tipologiaRate",
                   prtr.importo_rate "importoRate",
                   (select nvl(count(*), 0)
                      from rate_pratica rtpr
                     where rtpr.pratica = prtr.pratica) "numeroRate",
                   (select nvl(count(distinct rata), 0)
                      from versamenti vers
                     where vers.tipo_tributo = prtr.tipo_tributo
                       and vers.pratica = prtr.pratica
                       and vers.rata between 1 and prtr.rate) "rateVersate",
                    PRTR.TIPO_ATTO "codiceTipoAtto",
                    f_data_stampa(prtr.pratica) "dataStampa",
                    prtr.utente "utenteModifica",
                    f_descrizione_titr(prtr.tipo_tributo, prtr.anno) "tipoTributoAttuale",
                    tino.tipo_notifica "tipoNotificaId",
                    tino.descrizione "tipoNotificaDescrizione",
                    decode(soggetti.fascia,2,decode(soggetti.stato,50,'',
                                               decode(lpad(dati_generali.pro_cliente,3,'0') || lpad(dati_generali.com_cliente,3,'0'),
                                               lpad(soggetti.cod_pro_res,3,'0') || lpad(soggetti.cod_com_res,3,'0'),'ERR','')),'') "comuneResErr",
                    f_verifica_cap(soggetti.cod_pro_res,soggetti.cod_com_res,soggetti.cap) "capResErr",
                    itprmin.utente "utenteCreazione",
                    (select max(sapr.ruolo)
                      from ruoli ruol, sanzioni_pratica sapr
                         where ruol.ruolo = sapr.ruolo
                           and sapr.pratica = prtr.pratica) "ruoloCoattivo"
             from 
                (select sum(nvl(decode(versamenti.pratica,
                                          null,
                                          0,
                                          versamenti.importo_versato),
                                   0)) imp_versato,
                           max(versamenti.data_pagamento) data_pagam,
                           versamenti.pratica pratica,
                            count(*) as num_vers_filtrati
                     from versamenti
                     where 1 = 1
                       ${filtri.daAnno ? " and versamenti.anno >= :daAnno" : ""} 
                       ${filtri.aAnno ? " and versamenti.anno <= :aAnno" : ""}
                       ${filtri.daDataPagamento ? " and versamenti.data_pagamento >= to_date(:daDataPagamento, 'dd/mm/yyyy')" : ""} 
                       ${filtri.aDataPagamento ? " and versamenti.data_pagamento <= to_date(:aDataPagamento, 'dd/mm/yyyy')" : ""}
					   group by versamenti.pratica) vers,
                (SELECT
                    SUM(NVL(VERS2.IMPORTO_VERSATO,0)) IMP_VERSATO,
                    MAX(VERS2.DATA_PAGAMENTO) DATA_PAGAM,
                    COUNT(VERS2.PRATICA) AS NUM_VERS,
                    VERS2.PRATICA PRATICA
                    FROM VERSAMENTI VERS2
                    WHERE VERS2.PRATICA IS NOT NULL AND 
                    VERS2.TIPO_TRIBUTO||'' = '${filtri.tipoTributo}'
                GROUP BY VERS2.PRATICA) VERS_MULTI,
                   pratiche_tributo prtr,
                   rapporti_tributo ratr,
                   soggetti,
                   ad4_comuni,
                   ad4_provincie,
                   archivio_vie,
                   dati_generali,
                   contribuenti,
                   tipi_stato tist,
                   tipi_atto,
                   contribuenti_ente coen,
                   tipi_notifica tino,
                   (select pratica, utente
                     from (select itpr.utente,
                               itpr.pratica,
                               rank() over(partition by itpr.pratica order by itpr.data asc) rnk
                          from iter_pratica itpr)
                   where rnk = 1) itprmin
             where (${(filtri.daDataPagamento || filtri.aDataPagamento) ? "vers.pratica = prtr.pratica" : "vers.pratica(+) = prtr.pratica"})
                and prtr.pratica = VERS_MULTI.pratica (+)
               and (soggetti.ni = contribuenti.ni)
               and (soggetti.cod_via = archivio_vie.cod_via(+))
               and (soggetti.cod_pro_res = ad4_comuni.provincia_stato(+))
               and (soggetti.cod_com_res = ad4_comuni.comune(+))
               and (ad4_comuni.provincia_stato = ad4_provincie.provincia(+))
               and (prtr.pratica = ratr.pratica)
               and (contribuenti.cod_fiscale = ratr.cod_fiscale)
               and prtr.stato_accertamento = tist.tipo_stato(+)
               and prtr.tipo_atto = tipi_atto.tipo_atto(+)
               and prtr.tipo_notifica = tino.tipo_notifica(+)
               and prtr.pratica = itprmin.pratica(+)
               and (prtr.tipo_tributo || '' in (${tributiPraticheFiltro.tributi}) )
               and (prtr.tipo_pratica || '' in (${tributiPraticheFiltro.pratiche}))
               and (coen.ni = soggetti.ni)
               and (coen.tipo_tributo = prtr.tipo_tributo)
               ${filtri.daAnno ? "and prtr.anno(+) >= :daAnno" : ""} 
               ${filtri.aAnno ? "and prtr.anno(+) <= :aAnno" : ""} """


            // Residente
            if (filtri?.residente == "S") {
                sql += " and (soggetti.tipo_residente = 0 and soggetti.fascia = 1) "
            } else if (filtri?.residente == "N") {
                sql += " and (soggetti.tipo_residente <> 0 and soggetti.fascia <> 1) "
            }


            // Numero
            def daNumero = mappaFiltri?.daNumeroPratica
            def aNumero = mappaFiltri?.aNumeroPratica
            def isDaNumeroNotEmpty = daNumero != null && daNumero != ""
            def isANumeroNotEmpty = aNumero != null && aNumero != ""

            if (isDaNumeroNotEmpty) {
                if (daNumero.contains('%')) {
                    sql += " and upper(prtr.numero) like :daNumeroPratica "
                } else {
                    sql += " and lpad(upper(prtr.numero), 15, ' ') >= :daNumeroPratica "
                }
            }

            if (isANumeroNotEmpty) {
                sql += " and lpad(upper(prtr.numero), 15, ' ') <= :aNumeroPratica "
            }

            //Stato
            if (!filtri.tuttiTipiStatoSelezionati) {
                def condizioneStato = ""
                def listaTipi = ""
                def lista = filtri.tipiStatoSelezionati.collect { t -> t.tipoStato }
                HashSet<String> hs = new HashSet<String>(lista)
                hs.each { tipo ->
                    if (!tipo) {
                        condizioneStato += " prtr.stato_accertamento is null "
                    } else {
                        listaTipi += "'" + tipo + "',"
                    }
                }
                listaTipi = (listaTipi) ? listaTipi.substring(0, listaTipi.size() - 1) : ""
                if (condizioneStato != "" && listaTipi != "") {
                    condizioneStato += " or prtr.stato_accertamento in (" + listaTipi + ") "
                }

                if (condizioneStato == "" && listaTipi != "") {
                    condizioneStato += " prtr.stato_accertamento in (" + listaTipi + ") "
                }
                sql += """ ${condizioneStato ? " and ( ${condizioneStato} )" : ""} """
            }

            //Atto
            if (!filtri.tuttiTipiAttoSelezionati) {
                def condizioneAtto = ""
                def listaTipi = ""
                def lista = filtri.tipiAttoSelezionati.collect { t -> t.tipoAtto }
                HashSet<String> hs = new HashSet<String>(lista)
                hs.each { tipo ->
                    if (!tipo) {
                        condizioneAtto += " prtr.tipo_atto is null "
                    } else {
                        listaTipi += "'" + tipo + "',"
                    }
                }
                listaTipi = (listaTipi) ? listaTipi.substring(0, listaTipi.size() - 1) : ""
                if (condizioneAtto != "" && listaTipi != "") {
                    condizioneAtto += " or  prtr.tipo_atto in (" + listaTipi + ") "
                }

                if (condizioneAtto == "" && listaTipi != "") {
                    condizioneAtto += "  prtr.tipo_atto in (" + listaTipi + ") "
                }
                sql += """ ${condizioneAtto ? " and ( ${condizioneAtto} )" : ""} """
            }

            // lista stati/tipo atto
            if (filtri.statoAttiSelezionati != null) {

                def statoAttiSelezionati = filtri.statoAttiSelezionati
                String filtroStatiAtti

                if (statoAttiSelezionati.size() > 0) {
                    filtroStatiAtti = "'" + statoAttiSelezionati.join("','") + "'"
                } else {
                    filtroStatiAtti = "'_'"
                }
                sql += """ and (nvl(prtr.stato_accertamento,'-') || '_' || nvl(prtr.tipo_atto,0)) in(${filtroStatiAtti}) """
            }

            //Ruolo coattivo
            def filtroRuoloCoattivo = ""

            if (filtri.aRuolo && filtri.aRuolo != "T") {
                filtroRuoloCoattivo += """ and "ruoloCoattivo" ${filtri.aRuolo == "S" ? " IS NOT NULL " : " IS NULL "} """
            }

            sql += """ 
               ${filtri.statoSoggetto == "D" ? "AND SOGGETTI.STATO = 50 " : ""}
               ${filtri.statoSoggetto == "ND" ? "AND (SOGGETTI.STATO IS NULL OR SOGGETTI.STATO != 50)" : ""}
               ${filtri.daData ? " AND PRTR.DATA >= TO_DATE(:daData, 'dd/mm/yyyy')" : ""} 
               ${filtri.aData ? " AND PRTR.DATA <= TO_DATE(:aData, 'dd/mm/yyyy')" : ""}
               ${filtri.tipoNotifica ? " AND PRTR.TIPO_NOTIFICA = :tipoNotifica" : ""}
               ${filtri.daDataNotifica ? " AND PRTR.DATA_NOTIFICA >= TO_DATE(:daDataNotifica, 'dd/mm/yyyy')" : ""}
               ${filtri.aDataNotifica ? " AND PRTR.DATA_NOTIFICA <= TO_DATE(:aDataNotifica, 'dd/mm/yyyy')" : ""}
               ${filtri.nessunaDataNotifica ? " AND PRTR.DATA_NOTIFICA is null " : ""}
               ${filtri.daImporto != null ? " AND NVL(PRTR.IMPORTO_TOTALE, 0) >= :daImporto" : ""} 
               ${filtri.aImporto != null ? " AND NVL(PRTR.IMPORTO_TOTALE, 0) <= :aImporto" : ""}
               ${filtri.cf ? " AND UPPER(CONTRIBUENTI.COD_FISCALE) LIKE UPPER(:cf)" : ""} 
               ${filtri.cognome ? " AND UPPER(SOGGETTI.COGNOME) LIKE UPPER(:cognome)" : ""}
               ${filtri.nome ? " AND UPPER(SOGGETTI.NOME) LIKE UPPER(:nome)" : ""}
               ${filtri.numeroIndividuale ? " AND SOGGETTI.NI = :numeroIndividuale" : ""}
               ${filtri.codContribuente ? " AND CONTRIBUENTI.COD_CONTRIBUENTE = :codContribuente" : ""}
               ${filtri.inviatoPagoPa != 'T' ? filtri.inviatoPagoPa == 'S' ? " and prtr.flag_depag = 'S' " : " and prtr.flag_depag is null" : ""}
               AND ${speseNotificaOnPraticaSqlClause(filtri.conSpeseNotifica)}
               ${mappaFiltri.tipologiaRate ? " and nvl(prtr.tipologia_rate,'N') like :tipologiaRate" : ""}
               ${mappaFiltri.daImportoRateizzato ? " and prtr.importo_totale + nvl(prtr.mora,0) - nvl(prtr.versato_pre_rate,0) >= :daImportoRateizzato" : ""}
               ${mappaFiltri.aImportoRateizzato ? " and prtr.importo_totale + nvl(prtr.mora,0) - nvl(prtr.versato_pre_rate,0) <= :aImportoRateizzato" : ""}
			   ${mappaFiltri.daDataRateazione ? " and nvl(prtr.data_rateazione,to_date('01011901','ddmmyyyy')) >= TO_DATE(:daDataRateazione, 'dd/mm/yyyy')" : ""}
               ${mappaFiltri.aDataRateazione ? " and nvl(prtr.data_rateazione,to_date('01011901','ddmmyyyy')) <= TO_DATE(:aDataRateazione, 'dd/mm/yyyy')" : ""}
			   ${whereRate}
            )
			${whereStampa}
          ${filtroRuoloCoattivo}
        """

            params = params ?: [:]
            params.max = params.max ?: 10
            params.activePage = params.activePage ?: 0
            params.offset = params.activePage * params.max

            // Si restituisce, per l'inter lista, solo l'id pratica
            if (soloId) {
                params.max = Integer.MAX_VALUE
                output = eseguiQuery("$sql", mappaFiltri, params)
                        .collect {
                            [
                                    id        : it.pratica as Integer,
                                    impTotNum : it.impTot,
                                    clNumero  : it.clNumero,
                                    codFiscale: it.codFiscale
                            ]
                        }
            } else {

                // Numero totale di elementi
                def totale = eseguiQuery("""
                select count(*) as "totale",
                       sum("impTot") "totImpTot",
                       sum("importoRidotto") "totImportoRidotto",
                       sum("impVer") "totImpVer",
                       sum("totInteressi") "sumTotInteressi",
                       sum("totSanzioni") "sumTotSanzioni",
                       sum(nvl("importoDovuto", 0) - nvl("versatoPreRate", 0) - nvl("versato", 0)) "totImportoDaVersare",
                       sum("importoRateizzato") "totImportoRateizzato",
                       sum("importoInteressi") "totImportoInteressi",
                       sum(nvl("importoDovuto", 0) - nvl("versatoPreRate", 0)) "totImportoDovuto",
                       sum("versato") "totVersato",
                       sum("speseNotifica") "totNotifica"
				FROM ($sql)""", mappaFiltri, params, true)[0]

                String patternValuta = "€ #,##0.00"
                DecimalFormat valuta = new DecimalFormat(patternValuta)

                def pratiche = eseguiQuery("$sql $sortBySql", mappaFiltri, params).each { row ->

                    row.impTotNum = row.impTot

                    row.presenzaRate = !(row.presenzaRate == null)

                    row.data = row.data ? new Date(row.data.time).format("dd/MM/yyyy") : null
                    row.dataNotificaDate = row.dataNotifica
                    row.dataNotifica = row.dataNotifica ? new Date(row.dataNotifica.time).format("dd/MM/yyyy") : null
                    row.dataRateazione = row.dataRateazione ? new Date(row.dataRateazione.time).format("dd/MM/yyyy") : null
                    row.dataPag = row.dataPag ? new Date(row.dataPag.time).format("dd/MM/yyyy") : null

                    row.dataStampa = row.dataStampa ? new Date(row.dataStampa.time).format("dd/MM/yyyy") : null

                    row.impCNum = row.impC
                    row.totInteressiNum = row.totInteressi
                    row.totSanzioniNum = row.totSanzioni
                    row.versamentiNum = row.versamenti
                    row.impVerNum = row.impVer
                    row.impTotNum = row.impTot
                    row.importoDaVersareNum = (row.importoDovuto ?: 0.0) - (row.impVer ?: 0.0)
                    row.importoRidottoNum = row.importoRidotto

                    row.impC = row.impC ? valuta.format(row.impC) : null
                    row.totInteressi = row.totInteressi ? valuta.format(row.totInteressi) : null
                    row.totSanzioni = row.totSanzioni ? valuta.format(row.totSanzioni) : null
                    row.versamenti = row.versamenti ? valuta.format(row.versamenti) : null
                    row.impVer = row.impVer ? valuta.format(row.impVer) : null
                    row.impTot = row.impTot ? valuta.format(row.impTot) : null
                    row.importoRidotto = row.importoRidotto ? valuta.format(row.importoRidotto) : null

                    row.pratica = row.pratica as Integer

                    row.indirizzoPresso = ((row.nominativoPresso ?: "") + " " + (row.indirizzo ?: '')).trim()

                    row.importoRateizzatoNum = row.importoRateizzato
                    row.importoInteressiNum = row.importoInteressi
                    row.importoDovutoNum = (row.importoDovuto ?: 0) - (row.versatoPreRate ?: 0)
                    row.versatoNum = row.versato
                    row.tipologiaRateNum = row.tipologiaRate
                    row.importoRateNum = row.importoRate

                    row.importoDaVersare = valuta.format(row.importoDaVersareNum)
                    row.importoRateizzato = row.importoRateizzato ? valuta.format(row.importoRateizzato) : null
                    row.importoInteressi = row.importoInteressi ? valuta.format(row.importoInteressi) : null
                    row.importoDovuto = row.importoDovutoNum ? valuta.format(row.importoDovutoNum) : null
                    row.versato = row.versato ? valuta.format(row.versato) : valuta.format(0)
                    row.tipologiaRate = row.tipologiaRate ? rateazioneService.tipiRata[row.tipologiaRate] : null
                    row.importoRateNum = row.importoRate
                    row.importoRate = row.importoRate ? valuta.format(row.importoRate) : null

                    row.tipoNotifica = row.tipoNotificaId != null ? [
                            tipoNotifica: row.tipoNotificaId,
                            descrizione : row.tipoNotificaDescrizione
                    ] : null

                    row.isResidente = (row.fascia == 1 && row.tipoResidente == 0)

                    row.speseNotificaNum = row.speseNotifica ? valuta.format(row.speseNotifica) : null
                }

                def totImpTotFormatted = valuta.format(totale.totImpTot ?: 0)
                def totImportoRidottoFormatted = valuta.format(totale.totImportoRidotto ?: 0)
                def totImpVerFormatted = valuta.format(totale.totImpVer ?: 0)
                def sumTotInteressiFormatted = valuta.format(totale.sumTotInteressi ?: 0)
                def sumTotSanzioniFormatted = valuta.format(totale.sumTotSanzioni ?: 0)
                def totImportoDaVersareFormatted = valuta.format(totale.totImportoDaVersare ?: 0)
                def totImportoRateizzatoFormatted = valuta.format(totale.totImportoRateizzato ?: 0)
                def totImportoInteressiFormatted = valuta.format(totale.totImportoInteressi ?: 0)
                def totImportoDovutoFormatted = valuta.format(totale.totImportoDovuto ?: 0)
                def totVersatoFormatted = valuta.format(totale.totVersato ?: 0)
                def totSpeseNotificaFormatted = valuta.format(totale.totSpeseNotifica ?: 0)

                pratiche.each {
                    it.totImpTot = totImpTotFormatted
                    it.totImportoRidotto = totImportoRidottoFormatted
                    it.totImpVer = totImpVerFormatted
                    it.sumTotInteressi = sumTotInteressiFormatted
                    it.sumTotSanzioni = sumTotSanzioniFormatted
                    it.totImportoDaVersare = totImportoDaVersareFormatted
                    it.totImportoRateizzato = totImportoRateizzatoFormatted
                    it.totImportoInteressi = totImportoInteressiFormatted
                    it.totImportoDovuto = totImportoDovutoFormatted
                    it.totVersato = totVersatoFormatted
                    it.tipoAtto = TipoAtto.get(it.tipoAtto)
                    it.tipoAttoDescrizione = it.tipoAtto ? "${it.tipoAtto.tipoAtto} - ${it.tipoAtto.descrizione}" : ''
                    it.totSpeseNotifica = totSpeseNotificaFormatted

                    it.versamentiMultipli = it.versamentiMultipli > 1
                    it.dataPagamento = it.dataPagamento ? (it.dataPagamento + (it.versamentiMultipli ? " <" : "")) : null
                    it.versatoParziale = it.versatoParziale as String

                    it.impVer = it.versatoParziale == 'S' ? it.impVer + " *" : it.impVer
                }

                output = [
                        record      : pratiche,
                        numeroRecord: totale.totale
                ]
            }
        }

        log.info "Liquidazioni caricate in ${execTime}"

        return output
    }

    def caricaAccertamenti(def params, def filtri, def sortBy = null, def soloId = false) {

        def mappaFiltri = creaFiltriAccertamento(filtri)

        def sortBySql = ""

        sortBy.each { k, v ->
            if (v.verso) {
                // Esiste almeno un campo si crea la stringa Order By
                if (sortBySql.isEmpty()) {
                    sortBySql += "Order By\n"
                }

                switch (k) {
                    case 'codFiscale':
                        sortBySql += """\nlpad(upper("codFiscale"), 15, \' \') ${v.verso},"""
                        break
                    default:
                        sortBySql += """\n"$k" ${v.verso},"""
                        break
                }
            }
        }

        sortBySql = !sortBySql.isEmpty() ? sortBySql.substring(0, sortBySql.length() - 1) : ""
        def sql = """
            Select * from (
             select distinct upper(translate(soggetti.cognome_nome, '/', ' ')) "contribuente",
                f_determina_tipo_evento(prtr.pratica) "tipoViolazione",
                prtr.note "note",
                prtr.motivo "motivo",
                prtr.flag_depag "flagDePag",
                prtr.pratica "pratica",
                prtr.tipo_tributo "tipoTributo",
                f_importo_acc_lordo(prtr.pratica, 'S') "impRidLordo",
                contribuenti.cod_fiscale "codFiscale",
                soggetti.ni "ni",
                soggetti.tipo_residente "tipoResidente",
                soggetti.fascia "fascia",
                prtr.anno "anno",
                lpad(prtr.numero, 15) "clNumero",
                prtr.data "data",
                prtr.data_scadenza "dataScadenza",
                VERS.DATA_PAGAM "dataPag",
				DECODE(VERS_MULTI.DATA_PAGAM,NULL,NULL,TO_CHAR(VERS_MULTI.DATA_PAGAM,'DD/mm/yyyy')) "dataPagamento",
                CASE WHEN VERS_MULTI.num_vers != vers.num_vers_filtrati THEN 'S' ELSE 'N' END AS "versatoParziale",
                vers.imp_versato "impVer",
                nvl(prtr.versato_pre_rate, 0) as "versatoPreRate",
                NVL(VERS_MULTI.NUM_VERS,0) "versamentiMultipli",
                prtr.tipo_notifica "tipoNotifica",
                prtr.data_notifica "dataNotifica",
                tist.descrizione "statoAccertamento",
                f_importo_acc_lordo(prtr.pratica, 'N') "impAcc",
                upper(soggetti.cognome) "cognome",
                upper(soggetti.nome) "nome",
                prtr.importo_totale "impTot",
                f_importi_acc(prtr.pratica, 'S','NETTO') "impRid",
              --prtr.importo_ridotto "impRidPratica",
                soggetti.sesso "sesso",
                soggetti.data_nas "dataNascita",
                com_nas.denominazione ||
                 decode(pro_nas.sigla,
                        null,
                        '',
                        ' (' || pro_nas.sigla || ')') "comuneNascita",
                f_versato_pratica(prtr.pratica) "versato",
                f_importi_acc(prtr.pratica, 'N', 'ADD_ECA') "impAddEca",
                f_importi_acc(prtr.pratica, 'N', 'MAG_ECA') "impMagEca",
                f_importi_acc(prtr.pratica, 'N', 'ADD_PRO') "impAddPro",
                f_importi_acc(prtr.pratica, 'N', 'INTERESSI') "impInteressi",
                f_importi_acc(prtr.pratica, 'N', 'SANZIONI') "impSanzioni",
                f_importi_acc(prtr.pratica, 'S', 'SANZIONI') "impSanzioniRid",
                prtr.flag_adesione "flagAdesione",
                prtr.flag_denuncia "flagDenuncia",
                'Accertamenti ' ||
                f_descrizione_titr('TARSU',
                                   to_number(to_char(sysdate, 'yyyy'))) "titolo",
                prtr.tipo_evento "tipoEvento",
                f_importi_acc(prtr.pratica, 'N', 'MAGGIORAZIONE') "impMagTares",
                dati_generali.flag_acc_totale "flagAccTotale",
                coen.presso "nominativoPresso",
                coen.indirizzo "indirizzo",
                coen.comune_provincia "comuneProvincia",
                coen.cap "cap",
                PRTR.TIPO_PRATICA "tipoPratica",
                PRTR.pratica_rif "praticaRif",
                (select sum(sapr.importo)
                  from sanzioni_pratica sapr, sanzioni sanz
                 where sapr.cod_sanzione = sanz.cod_sanzione
                   and sapr.sequenza_sanz = sanz.sequenza
                   and sapr.tipo_tributo = sanz.tipo_tributo
                   and sanz.tipo_causale = 'S'
                   and sapr.pratica = prtr.pratica) "speseNotifica",
                (SELECT MAX(1)
                      FROM RATE_PRATICA RTPR
                     WHERE RTPR.PRATICA = PRTR.PRATICA) "presenzaRate",
                    prtr.importo_totale + nvl(prtr.mora, 0) -
                   nvl(prtr.versato_pre_rate, 0) "importoRateizzato",
                   decode(nvl(prtr.rate, 0),
                          0,
                          0,
                          round(prtr.importo_rate * prtr.rate, 2) -
                          (prtr.importo_totale + nvl(prtr.mora, 0) -
                           nvl(prtr.versato_pre_rate, 0))) "importoInteressi",
                   decode(nvl(prtr.rate, 0),
                          0,
                          prtr.importo_totale + nvl(prtr.mora, 0) -
                          nvl(prtr.versato_pre_rate, 0),
                          round((select sum(sapr.importo)
                              from sanzioni_pratica sapr
                             where sapr.pratica = prtr.pratica),
                            2)) "importoDovuto",
                   (select nvl(sum(importo_versato), 0)
                      from versamenti vers
                     where vers.tipo_tributo = prtr.tipo_tributo
                       and vers.pratica = prtr.pratica
                       and vers.rata between 1 and prtr.rate) "versatoRate",
                   prtr.tipologia_rate "tipologiaRate",
                   prtr.importo_rate importo_rate,
                   (select nvl(count(*), 0)
                      from rate_pratica rtpr
                     where rtpr.pratica = prtr.pratica) "numeroRate",
                   (select nvl(count(distinct rata), 0)
                      from versamenti vers
                     where vers.tipo_tributo = prtr.tipo_tributo
                       and vers.pratica = prtr.pratica
                       and vers.rata between 1 and prtr.rate) "rateVersate",
                    PRTR.TIPO_ATTO "codiceTipoAtto",
                    prtr.utente "utenteModifica",
                    (select max(ruco.ruolo)
                        from ruoli_contribuente ruco
                            where ruco.pratica = prtr.pratica) "ruoloCoattivo",
                    f_descrizione_titr(prtr.tipo_tributo, prtr.anno) "tipoTributoAttuale",
                    tino.tipo_notifica "tipoNotificaId",
                    tino.descrizione "tipoNotificaDescrizione",
                    itprmin.utente "utenteCreazione",
                    decode(soggetti.fascia,2,decode(soggetti.stato,50,'',
                           decode(lpad(dati_generali.pro_cliente,3,'0') || lpad(dati_generali.com_cliente,3,'0'),
                           lpad(soggetti.cod_pro_res,3,'0') || lpad(soggetti.cod_com_res,3,'0'),'ERR','')),'') "comuneResErr",
                    f_verifica_cap(soggetti.cod_pro_res,soggetti.cod_com_res,soggetti.cap) "capResErr"
              from 
				 ( SELECT
                        count(*) as num_vers_filtrati,
						SUM(NVL(DECODE(VERS1.PRATICA,NULL,0,VERS1.IMPORTO_VERSATO),0)) IMP_VERSATO,
						MAX(VERS1.DATA_PAGAMENTO) DATA_PAGAM,
						VERS1.PRATICA PRATICA
					FROM VERSAMENTI VERS1
					WHERE 1 = 1
						${filtri.daAnno ? " AND VERS1.ANNO >= :daAnno" : ""} 
						${filtri.aAnno ? " AND VERS1.ANNO <= :aAnno" : ""}
						${filtri.daDataPagamento ? " AND VERS1.DATA_PAGAMENTO >= TO_DATE(:daDataPagamento, 'dd/mm/yyyy')" : ""} 
						${filtri.aDataPagamento ? " AND VERS1.DATA_PAGAMENTO <= TO_DATE(:aDataPagamento, 'dd/mm/yyyy')" : ""}
					GROUP BY VERS1.PRATICA) VERS,
	               (SELECT
						SUM(NVL(VERS2.IMPORTO_VERSATO,0)) IMP_VERSATO,
						MAX(VERS2.DATA_PAGAMENTO) DATA_PAGAM,
						COUNT(VERS2.PRATICA) AS NUM_VERS,
						VERS2.PRATICA PRATICA
					FROM VERSAMENTI VERS2
					WHERE VERS2.PRATICA IS NOT NULL AND 
						  VERS2.TIPO_TRIBUTO||'' = :tipoTributo
					GROUP BY VERS2.PRATICA) VERS_MULTI,
                   pratiche_tributo  prtr,
                   rapporti_tributo  ratr,
                   soggetti,
                   contribuenti,
                   archivio_vie,
                   oggetti_pratica,
                   ad4_comuni       com_nas,
                   ad4_provincie    pro_nas,
                   tipi_stato        tist,
                   dati_generali,
                   contribuenti_ente coen,
                   tipi_notifica tino,
                   (select pratica, utente
                     from (select itpr.utente,
                               itpr.pratica,
                               rank() over(partition by itpr.pratica order by itpr.data asc) rnk
                          from iter_pratica itpr)
                   where rnk = 1) itprmin
             where
                (${(filtri.daDataPagamento || filtri.aDataPagamento) ? "VERS.PRATICA = PRTR.PRATICA" : "VERS.PRATICA(+) = PRTR.PRATICA"})
               and (soggetti.ni = contribuenti.ni)
               and (contribuenti.cod_fiscale = ratr.cod_fiscale)
               and (prtr.pratica = ratr.pratica)
               AND (PRTR.TIPO_TRIBUTO || '' = :tipoTributo)
               AND (PRTR.TIPO_PRATICA || '' = :tipoPratica)
               and (prtr.pratica = oggetti_pratica.pratica(+))
               and ((prtr.pratica_rif is null) or
                   (prtr.pratica_rif is not null and
                   substr(f_pratica(prtr.pratica_rif), 1, 1) <> 'A'))
               and prtr.stato_accertamento = tist.tipo_stato(+)
               and (soggetti.cod_via = archivio_vie.cod_via(+))
               and (coen.ni = soggetti.ni)
               and (coen.tipo_tributo = prtr.tipo_tributo)
               and (soggetti.cod_pro_nas = com_nas.provincia_stato(+))
               and (soggetti.cod_com_nas = com_nas.comune(+))
               and (com_nas.provincia_stato = pro_nas.provincia(+))
               and prtr.tipo_notifica = tino.tipo_notifica(+)
               and prtr.pratica = itprmin.pratica (+)
			   and prtr.pratica = VERS_MULTI.pratica (+)
               ${filtri.daAnno ? "AND PRTR.ANNO(+) >= :daAnno" : ""} 
               ${filtri.aAnno ? "AND PRTR.ANNO(+) <= :aAnno" : ""} """
        //Stato
        if (!filtri.tuttiTipiStatoSelezionati) {
            def condizioneStato = ""
            def listaTipi = ""
            def lista = filtri.tipiStatoSelezionati.collect { t -> t.tipoStato }
            HashSet<String> hs = new HashSet<String>(lista)
            hs.each { tipo ->
                if (!tipo) {
                    condizioneStato += " prtr.stato_accertamento is null "
                } else {
                    listaTipi += "'" + tipo + "',"
                }
            }
            listaTipi = (listaTipi) ? listaTipi.substring(0, listaTipi.size() - 1) : ""
            if (condizioneStato != "" && listaTipi != "") {
                condizioneStato += " or prtr.stato_accertamento in (" + listaTipi + ") "
            }

            if (condizioneStato == "" && listaTipi != "") {
                condizioneStato += " prtr.stato_accertamento in (" + listaTipi + ") "
            }
            sql += """ ${condizioneStato ? " and ( ${condizioneStato} )" : ""} """
        }

        //Atto
        if (!filtri.tuttiTipiAttoSelezionati) {
            def condizioneAtto = ""
            def listaTipi = ""
            def lista = filtri.tipiAttoSelezionati.collect { t -> t.tipoAtto }
            HashSet<String> hs = new HashSet<String>(lista)
            hs.each { tipo ->
                if (!tipo) {
                    condizioneAtto += " prtr.tipo_atto is null "
                } else {
                    listaTipi += "'" + tipo + "',"
                }
            }
            listaTipi = (listaTipi) ? listaTipi.substring(0, listaTipi.size() - 1) : ""
            if (condizioneAtto != "" && listaTipi != "") {
                condizioneAtto += " or  prtr.tipo_atto in (" + listaTipi + ") "
            }

            if (condizioneAtto == "" && listaTipi != "") {
                condizioneAtto += "  prtr.tipo_atto in (" + listaTipi + ") "
            }
            sql += """ ${condizioneAtto ? " and ( ${condizioneAtto} )" : ""} """
        }

        // lista stati/tipo atto
        if (filtri.statoAttiSelezionati != null) {

            def statoAttiSelezionati = filtri.statoAttiSelezionati
            String filtroStatiAtti

            if (statoAttiSelezionati.size() > 0) {
                filtroStatiAtti = "'" + statoAttiSelezionati.join("','") + "'"
            } else {
                filtroStatiAtti = "'_'"
            }
            sql += """ and (nvl(prtr.stato_accertamento,'-') || '_' || nvl(prtr.tipo_atto,0)) in(${filtroStatiAtti}) """
        }

        // Numero
        def daNumero = mappaFiltri?.daNumeroPratica
        def aNumero = mappaFiltri?.aNumeroPratica
        def isDaNumeroNotEmpty = daNumero != null && daNumero != ""
        def isANumeroNotEmpty = aNumero != null && aNumero != ""

        if (isDaNumeroNotEmpty) {
            if (daNumero.contains('%')) {
                sql += " and upper(prtr.numero) like :daNumeroPratica "
            } else {
                sql += " and lpad(upper(prtr.numero), 15, ' ') >= :daNumeroPratica "
            }
        }

        if (isANumeroNotEmpty) {
            sql += " and lpad(upper(prtr.numero), 15, ' ') <= :aNumeroPratica "
        }


        // Residente
        if (filtri?.residente == "S") {
            sql += " and (soggetti.tipo_residente = 0 and soggetti.fascia = 1) "
        } else if (filtri?.residente == "N") {
            sql += " and (soggetti.tipo_residente <> 0 and soggetti.fascia <> 1) "
        }

        sql += """ 
               ${filtri.statoSoggetto == "D" ? "AND SOGGETTI.STATO = 50 " : ""}
               ${filtri.statoSoggetto == "ND" ? "AND (SOGGETTI.STATO IS NULL OR SOGGETTI.STATO != 50)" : ""}
               ${filtri.daData ? " AND PRTR.DATA >= TO_DATE(:daData, 'dd/mm/yyyy')" : ""} 
               ${filtri.aData ? " AND PRTR.DATA <= TO_DATE(:aData, 'dd/mm/yyyy')" : ""}
               ${filtri.tipoNotifica ? " AND PRTR.TIPO_NOTIFICA = :tipoNotifica" : ""}
               ${filtri.daDataNotifica ? " AND PRTR.DATA_NOTIFICA >= TO_DATE(:daDataNotifica, 'dd/mm/yyyy')" : ""}
               ${filtri.aDataNotifica ? " AND PRTR.DATA_NOTIFICA <= TO_DATE(:aDataNotifica, 'dd/mm/yyyy')" : ""}
               ${filtri.nessunaDataNotifica ? " AND PRTR.DATA_NOTIFICA is null " : ""}
               ${filtri.daImporto != null ? " AND NVL(PRTR.IMPORTO_TOTALE, 0) >= :daImporto" : ""} 
               ${filtri.aImporto != null ? " AND NVL(PRTR.IMPORTO_TOTALE, 0) <= :aImporto" : ""}
               ${filtri.cf ? " AND UPPER(CONTRIBUENTI.COD_FISCALE) LIKE UPPER(:cf)" : ""} 
               ${filtri.cognome ? " AND UPPER(SOGGETTI.COGNOME) LIKE UPPER(:cognome)" : ""}
               ${filtri.nome ? " AND UPPER(SOGGETTI.NOME) LIKE UPPER(:nome)" : ""}
               ${filtri.numeroIndividuale ? " AND SOGGETTI.NI = :numeroIndividuale" : ""}
               ${filtri.codContribuente ? " AND CONTRIBUENTI.COD_CONTRIBUENTE = :codContribuente" : ""}
               ${filtri.daDataScadenza && filtri.tipoPratica == "S" ? " AND PRTR.DATA_SCADENZA >= :daDataScadenza" : ""}
               ${filtri.aDataScadenza && filtri.tipoPratica == "S" ? " AND PRTR.DATA_SCADENZA <= :aDataScadenza" : ""}
               ${filtri.inviatoPagoPa != 'T' ? filtri.inviatoPagoPa == 'S' ? " and prtr.flag_depag = 'S' " : " and prtr.flag_depag is null" : ""}
               AND ${speseNotificaOnPraticaSqlClause(filtri.conSpeseNotifica)}

               AND ((:codVia = -1 and :daCivico = -1 and :aCivico = -1) or exists
                 (select 1
                          from oggetti ogge
                         where ogge.oggetto = oggetti_pratica.oggetto
                           and ogge.cod_via = decode(:codVia,  -1, ogge.cod_via, :codVia)
                           and (nvl(ogge.num_civ, 0) between decode(:daCivico, -1, 0, :daCivico) and decode(:aCivico, -1, 999999, :aCivico))
                        ))
               ${mappaFiltri.titoloOccupazione ? "and oggetti_pratica.titolo_occupazione(+) = :titoloOccupazione" : ""}
               ${mappaFiltri.naturaOccupazione ? "and oggetti_pratica.natura_occupazione(+) = :naturaOccupazione" : ""}
               ${mappaFiltri.destinazioneUso ? "and oggetti_pratica.destinazione_uso(+) = :destinazioneUso" : ""}
               ${mappaFiltri.assenzaEstremiCat ? "and oggetti_pratica.assenza_estremi_catasto(+) = :assenzaEstremiCat" : ""}
			   ${mappaFiltri.tipologiaRate ? " and nvl(prtr.tipologia_rate,'N') like :tipologiaRate" : ""}
               ${
            mappaFiltri.daImportoRateizzato ? " and prtr.importo_totale + nvl(prtr.mora,0) - nvl(prtr.versato_pre_rate,0) >= :daImportoRateizzato" : ""
        }
               ${
            mappaFiltri.aImportoRateizzato ? " and prtr.importo_totale + nvl(prtr.mora,0) - nvl(prtr.versato_pre_rate,0) <= :aImportoRateizzato" : ""
        }
			   ${
            mappaFiltri.daDataRateazione ? " and nvl(prtr.data_rateazione,to_date('01011901','ddmmyyyy')) >= TO_DATE(:daDataRateazione, 'dd/mm/yyyy')" : ""
        }
               ${
            mappaFiltri.aDataRateazione ? " and nvl(prtr.data_rateazione,to_date('01011901','ddmmyyyy')) <= TO_DATE(:aDataRateazione, 'dd/mm/yyyy')" : ""
        }
         

                ${
            (mappaFiltri.aRuolo && mappaFiltri.aRuolo != 'T') ? """ and (
                    (:aRuolo = 'S' and exists (select 1
                        from ruoli_contribuente ruco
                            where ruco.pratica = prtr.pratica)) or
                     (:aRuolo = 'N' and not exists (select 1
                        from ruoli_contribuente ruco
                            where ruco.pratica = prtr.pratica)))""" : ""
        }
                ${filtri.flagDenuncia != 'T' && filtri.tipoPratica != "S" ? "and nvl(prtr.flag_denuncia, 'N') = :flagDenuncia" : ""}
                ${mappaFiltri.tipoEvento != null && mappaFiltri.tipoEvento != 'TUTTI' && filtri.tipoPratica != 'S' ? "and prtr.tipo_evento = :tipoEvento" : ""}
                ${
            (mappaFiltri.flagPossesso && mappaFiltri.flagPossesso != 'T' && filtri.tipoTributo != 'TARSU') ? """
                    and exists (select 1
            from oggetti_pratica op4, oggetti_contribuente oc4
           where op4.oggetto_pratica = oc4.oggetto_pratica
             and op4.pratica = ratr.pratica
             and oc4.cod_fiscale = ratr.cod_fiscale
             and (nvl(oc4.flag_possesso, 'N') = :flagPossesso ))""" : ""
        }
                ${
            (mappaFiltri.tipoRapporto && mappaFiltri.tipoRapporto != 'T' && filtri.tipoTributo == 'TASI') ? "and ratr.tipo_rapporto = :tipoRapporto" : ""
        }
                ${
            (mappaFiltri.soloPraticheTotali && filtri.tipoTributo != 'TARSU') ? "and prtr.tipo_evento = :soloPraticheTotali" : ""
        }
                and ((:daCategoria = -1 and :aCategoria = -1 and :daTariffa = -1 and :aTariffa = -1 ) or exists (select 1
                  from oggetti_pratica ogpr
                 where ogpr.pratica = prtr.pratica
                   ${filtri.codiceTributo ? "and ogpr.tributo = :codiceTributo" : ""}
                   and nvl(ogpr.categoria, 0) between decode(:daCategoria, -1, 0, :daCategoria) and decode(:aCategoria, -1, 9999, :aCategoria)
                   and nvl(ogpr.tipo_tariffa, 0) between decode(:daTariffa, -1, 0, :daTariffa) and decode(:aTariffa, -1, 99, :aTariffa)))
                and nvl(oggetti_pratica.data_anagrafe_tributaria(+),
                    to_date('01/01/1901', 'dd/mm/yyyy')) between
                    to_date(:daDataAnagrafeTributaria, 'dd/mm/yyyy') and
                    to_date(:aDataAnagrafeTributaria, 'dd/mm/yyyy')
                
        )
		"""

        if (filtri.tipoAttoSanzione != 'T' && filtri.tipoPratica != 'S' && filtri.tipoTributo in ['TARSU', 'ICI', 'TASI', 'TOSAP', 'ICP', 'CUNI']) {
            sql += """
                where f_determina_tipo_evento("pratica") = :tipoAttoSanzione
            """
        }


        params = params ?: [:]
        params.max = params.max ?: 10
        params.activePage = params.activePage ?: 0
        params.offset = params.activePage * params.max

        // Si restituisce, per l'inter lista, solo l'id pratica
        if (soloId) {
            params.max = Integer.MAX_VALUE
            return eseguiQuery("$sql", mappaFiltri, params)
                    .collect {
                        [
                                id        : it.pratica as Integer,
                                impTotNum : it.impTot,
                                clNumero  : it.clNumero,
                                codFiscale: it.codFiscale,
                                tipoEvento: it.tipoEvento
                        ]
                    }
        }

        String patternValuta = "€ #,##0.00"
        DecimalFormat valuta = new DecimalFormat(patternValuta)

        def tipoViolazione = [
                ID: 'Infedele Denuncia',
                OD: 'Omessa Denuncia',
                TD: 'Tardiva Denuncia',
                OV: 'Omesso Versamento',
                TV: 'Tardivo Versamento',
                AL: 'Altro'
        ]

        sql = """select ACCERTAMENTI.*, 
                    count(*) over() "totale",
                    sum("impRidLordo") over() "totImpRidLordoNum",
                    sum("impAcc") over() "totImpAccNum",
                    sum("impTot") over() "totImpTotNum",
                    sum("impRid") over() "totImpRidNum",
                    sum("impAddEca") over() "totImpAddEcaNum",
                    sum("impMagEca") over() "totImpMagEcaNum",
                    sum("impAddPro") over() "totImpAddProNum",
                    sum("impInteressi") over() "totImpInteressiNum",
                    sum("impSanzioni") over() "totImpSanzioniNum",
                    sum("impSanzioniRid") over() "totImpSanzioniRidNum",
                    sum("impMagTares") over() "totImpMagTaresNum",
                    sum("versato") over() "toImpVersatoNum",
                    sum(nvl("importoDovuto", 0) - nvl("versato", 0)) over() "totImportoDaVersareNum",
                    sum("importoRateizzato") over() "totImportoRateizzatoNum",
                    sum("importoInteressi") over() "totImportoInteressiNum",
                    sum("importoDovuto") over() "totImportoDovutoNum",
                    sum("versatoRate") over() "totVersatoRateNum",
                    sum("speseNotifica") over() "totSpeseNotifica"
                from (select * from ($sql $sortBySql)) ACCERTAMENTI"""

        def inizializzaTotali = true

        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")

        def pratiche = eseguiQuery("$sql", mappaFiltri, params).each { row ->

            row.pratica = row.pratica as Integer
            row.id = row.pratica

            row.indirizzoPresso = ((row.nominativoPresso ?: "") + " " + (row.indirizzo ?: '')).trim()

            row.data = row.data ? new Date(row.data.time).format("dd/MM/yyyy") : null
            row.dataNotifica = row.dataNotifica ? new Date(row.dataNotifica.time).format("dd/MM/yyyy") : null
            row.dataNascita = row.dataNascita ? new Date(row.dataNascita.time).format("dd/MM/yyyy") : null

            row.dataNotificaDate = row.dataNotifica ? sdf.parse(row.dataNotifica) : null

            row.impRidLordoNum = row.impRidLordo
            row.impAccNum = row.impAcc
            row.impTotNum = row.impTot
            row.impRidNum = row.impRid
            row.impMagEcaNum = row.impMagEca
            row.impAddEcaNum = row.impAddEca
            row.impAddProNum = row.impAddPro
            row.impInteressiNum = row.impInteressi
            row.impSanzioniNum = row.impSanzioni
            row.impSanzioniRidNum = row.impSanzioniRid
            row.impMagTaresNum = row.impMagTares
            row.versatoNum = row.versato

            row.impRidLordo = row.impRidLordo ? valuta.format(row.impRidLordo) : null
            row.impAcc = row.impAcc ? valuta.format(row.impAcc) : null
            row.totInteressi = row.totInteressi ? valuta.format(row.totInteressi) : null
            row.totSanzioni = row.totSanzioni ? valuta.format(row.totSanzioni) : null
            row.impTot = row.impTot ? valuta.format(row.impTot) : null
            row.impRid = row.impRid ? valuta.format(row.impRid) : null
            row.impMagEca = (row.impMagEca != null) ? valuta.format(row.impMagEca) : null
            row.impAddEca = (row.impAddEca != null) ? valuta.format(row.impAddEca) : null
            row.impAddPro = (row.impAddPro != null) ? valuta.format(row.impAddPro) : null
            row.impInteressi = row.impInteressi ? valuta.format(row.impInteressi) : null
            row.impSanzioni = row.impSanzioni ? valuta.format(row.impSanzioni) : null
            row.impSanzioniRid = row.impSanzioniRid ? valuta.format(row.impSanzioniRid) : null
            row.impMagTares = (row.impMagTares != null) ? valuta.format(row.impMagTares) : null
            row.versato = row.versato ? valuta.format(row.versato) : null
            row.sesso = row.sesso ? (row.sesso == 'M' ? 'Maschio' : 'Femmina') : null
            row.tipoEventoChar = (row.tipoEvento == 'T' ? 'S' : null)
            row.tipoTributoAttuale = TipoTributo.get(row.tipoTributo)?.toDTO()?.getTipoTributoAttuale(row.anno as Short)
            row.dataPag = row.dataPag ? new Date(row.dataPag.time).format("dd/MM/yyyy") : null
            row.importoDaVersareNum = (row.importoDovuto ?: 0) - (row.versatoNum ?: 0)
            row.importoRateizzatoNum = row.importoRateizzato
            row.importoInteressiNum = row.importoInteressi
            row.importoDovutoNum = (row.importoDovuto ?: 0) - (row.versatoPreRate ?: 0)
            row.versatoRateNum = row.versatoRate
            row.importoRateNum = row.importoRate

            row.importoDaVersare = valuta.format((row.importoDovuto ?: 0) - (row.versatoRate ?: 0))
            row.importoRateizzato = row.importoRateizzato ? valuta.format(row.importoRateizzato) : null
            row.importoInteressi = row.importoInteressi ? valuta.format(row.importoInteressi) : null
            row.importoDovuto = row.importoDovutoNum ? valuta.format(row.importoDovutoNum) : null
            row.versatoRate = row.versatoRate ? valuta.format(row.versatoRate) : null
            row.tipologiaRate = row.tipologiaRate ? rateazioneService.tipiRata[row.tipologiaRate] : null
            row.importoRate = row.importoRate ? valuta.format(row.importoRate) : null
            row.tipoAtto = OggettiCache.TIPI_ATTO.valore.find { it.tipoAtto == row.codiceTipoAtto }

            row.tipoEventoViolazione = row.tipoViolazione != null ?
                    "${row.tipoEvento} - ${row.tipoViolazione}" : row.tipoEvento
            row.tipoEventoViolazioneTooltip = row.tipoViolazione != null ?
                    "${row.tipoEvento} - ${tipoViolazione[row.tipoViolazione]}" : ''

            row.tipoNotifica = row.tipoNotificaId != null ? [
                    tipoNotifica: row.tipoNotifica,
                    descrizione : row.tipoNotificaDescrizione
            ] : null

            if (inizializzaTotali) {
                inizializzaTotali = false
                row.totImpRidLordo = valuta.format(row.totImpRidLordoNum ?: 0)
                row.totImpAcc = valuta.format(row.totImpAccNum ?: 0)
                row.sumTotInteressi = valuta.format(row.sumTotInteressiNum ?: 0)
                row.sumTotSanzioni = valuta.format(row.sumTotSanzioniNum ?: 0)
                row.totImpTot = valuta.format(row.totImpTotNum ?: 0)
                row.totImpRid = valuta.format(row.totImpRidNum ?: 0)
                row.totImpAddEca = valuta.format(row.totImpAddEcaNum ?: 0)
                row.totImpMagEca = valuta.format(row.totImpMagEcaNum ?: 0)
                row.totImpAddPro = valuta.format(row.totImpAddProNum ?: 0)
                row.totImpInteressi = valuta.format(row.totImpInteressiNum ?: 0)
                row.totImpSanzioni = valuta.format(row.totImpSanzioniNum ?: 0)
                row.totImpSanzioniRid = valuta.format(row.totImpSanzioniRidNum ?: 0)
                row.totImpMagTares = valuta.format(row.totImpMagTaresNum ?: 0)
                row.totImpVersato = valuta.format(row.toImpVersatoNum ?: 0)
                row.totImportoDaVersare = valuta.format(row.totImportoDaVersareNum ?: 0)
                row.totImportoRateizzato = valuta.format(row.totImportoRateizzatoNum ?: 0)
                row.totImportoInteressi = valuta.format(row.totImportoInteressiNum ?: 0)
                row.totImportoDovuto = valuta.format(row.totImportoDovutoNum ?: 0)
                row.totVersatoRate = valuta.format(row.totVersatoRateNum ?: 0)
                row.totSpeseNotifica = valuta.format(row.totSpeseNotifica ?: 0)
            }

            row.isResidente = (row.fascia == 1 && row.tipoResidente == 0)

            row.versamentiMultipli = row.versamentiMultipli > 1
            row.dataPagamento = row.dataPagamento ? (row.dataPagamento + (row.versamentiMultipli ? " <" : "")) : null
            row.speseNotificaNum = row.speseNotifica ? valuta.format(row.speseNotifica) : null
            row.versatoParziale = row.versatoParziale as String
            row.impVerNum = row.impVer
            row.impVer = row.impVer ? valuta.format(row.impVer) : null
            row.impVer = row.versatoParziale == 'S' ? row.impVer + " *" : row.impVer
        }

        if (filtri.tipoPratica == 'S') {

            def listaVersamenti = [:]
            if (!pratiche.empty) {
                def idList = pratiche.collect { it.id as Long }

                idList.collate(1000).each { subList ->
                    def results = Versamento.executeQuery("""
                            select pratica.id, sum(importoVersato), min(dataPagamento), count(pratica.id) 
                            from Versamento 
                            where pratica.id in :pList 
                            group by pratica.id""",
                            [pList: subList])

                    listaVersamenti += results.collectEntries { [(it[0]): [multi: it[3] > 1, tot: it[1], data: it[2]]] }
                }
            }

            pratiche.each {
                it.dataPagamento =
                        (listaVersamenti[it.id as Long]?.data ?
                                (new SimpleDateFormat("dd/MM/yyyy")).format(listaVersamenti[it.id as Long]?.data) : "").toString() + (listaVersamenti[it.id as Long]?.multi ? " <" : "")
                it.versamentiMultipli = listaVersamenti[it.id as Long]?.multi
            }
        }


        return [
                record      : pratiche,
                numeroRecord: pratiche.empty ? null : pratiche[0].totale
        ]
    }

    private eseguiQuery(def query, def filtri, def params, def count = false) {

        filtri = filtri ?: [:]

        if (!query || (query as String).isEmpty()) {
            throw new RuntimeException("Query non specificata.")
        }

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(query)
        sqlQuery.with {

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            filtri.each { k, v ->
                setParameter(k, v)
            }

            if (!count) {
                setFirstResult(params.offset)
                setMaxResults(params.max)
            }

            list()
        }
    }

    private def creaFiltriTipoTributoEPratica(def filtri) {
        def tributi = ""
        def pratiche = ""

        tributi += "'${filtri.tipoTributo}'"

        // Il tipo pratica va gestito solo per ICI e TASI o TARI E CUNI
        if (filtri.tipoTributo in ['ICI', 'TASI', 'TARSU', 'CUNI']) {
            if (filtri.tipoPratica == '*') {

                // TODO - Tipo da gestire con la  #62142
                filtri.rateizzate.tipo.S = false

                filtri.rateizzate.tipo.findAll { it.value }.each {
                    pratiche += "'${it.key}',"

                }

                pratiche = pratiche.empty ? pratiche : pratiche[0..-2]

            } else {
                pratiche += "'${filtri.tipoPratica}'"
            }
        } else {
            pratiche = "'A','L'"
        }

        return [tributi: tributi, pratiche: pratiche?.empty ? "''" : pratiche]
    }

    private creaFiltriLiquidazioni(def filtri) {

        def mappaFiltri = [:]

        if (filtri.daAnno) {
            mappaFiltri << ['daAnno': filtri.daAnno]
        }
        if (filtri.aAnno) {
            mappaFiltri << ['aAnno': filtri.aAnno]
        }

        if (filtri.daDataPagamento) {
            mappaFiltri << ['daDataPagamento': filtri.daDataPagamento?.format('dd/MM/yyyy') ?: '01/01/1800']
        }
        if (filtri.aDataPagamento) {
            mappaFiltri << ['aDataPagamento': filtri.aDataPagamento?.format('dd/MM/yyyy') ?: '31/12/9999']
        }

        // Numero
        def isDaNumeroNotEmpty = filtri.daNumeroPratica != null && filtri.daNumeroPratica != ""
        def isANumeroNotEmpty = filtri.aNumeroPratica != null && filtri.aNumeroPratica != ""


        if (isDaNumeroNotEmpty) {
            if (filtri.daNumeroPratica.contains('%')) {
                mappaFiltri << ['daNumeroPratica': (filtri.daNumeroPratica as String).toUpperCase()]
            } else {
                mappaFiltri << ['daNumeroPratica': (filtri.daNumeroPratica as String).padLeft(15, " ").toUpperCase()]
            }
        }

        if (isANumeroNotEmpty) {
            if (!isDaNumeroNotEmpty || (isDaNumeroNotEmpty && !filtri.daNumeroPratica.contains('%'))) {
                mappaFiltri << ['aNumeroPratica': (filtri.aNumeroPratica as String).padLeft(15, " ").toUpperCase()]
            }
        }

        if (filtri.daData) {
            mappaFiltri << ['daData': filtri.daData.format('dd/MM/yyyy')]
        }
        if (filtri.aData) {
            mappaFiltri << ['aData': filtri.aData.format('dd/MM/yyyy')]
        }

        if (filtri.tipoNotifica) {
            mappaFiltri << ['tipoNotifica': filtri.tipoNotifica.tipoNotifica]
        }

        if (filtri.daDataNotifica) {
            mappaFiltri << ['daDataNotifica': filtri.daDataNotifica.format('dd/MM/yyyy')]
        }
        if (filtri.aDataNotifica) {
            mappaFiltri << ['aDataNotifica': filtri.aDataNotifica.format('dd/MM/yyyy')]
        }

        if (filtri.daImporto != null) {
            mappaFiltri << ['daImporto': filtri.daImporto]
        }
        if (filtri.aImporto != null) {
            mappaFiltri << ['aImporto': filtri.aImporto]
        }

        if (filtri.cognome) {
            mappaFiltri << ['cognome': filtri.cognome]
        }
        if (filtri.nome) {
            mappaFiltri << ['nome': filtri.nome]
        }
        if (filtri.numeroIndividuale) {
            mappaFiltri << ['numeroIndividuale': filtri.numeroIndividuale]
        }
        if (filtri.codContribuente) {
            mappaFiltri << ['codContribuente': filtri.codContribuente]
        }
        if (filtri.cf) {
            mappaFiltri << ['cf': filtri.cf]
        }

        def lista = filtri.tipiAttoSelezionati.collect { t -> t.tipoAtto }
        lista.each { tipo ->
            if (tipo && tipo == 90) {
                if (filtri.tipologiaRate) {
                    mappaFiltri << ['tipologiaRate': filtri.tipologiaRate]
                }

                if (filtri.daImportoRateizzato) {
                    mappaFiltri << ['daImportoRateizzato': filtri.daImportoRateizzato]
                }
                if (filtri.aImportoRateizzato) {
                    mappaFiltri << ['aImportoRateizzato': filtri.aImportoRateizzato]
                }

                if (filtri.daDataRateazione) {
                    mappaFiltri << ['daDataRateazione': filtri.daDataRateazione.format('dd/MM/yyyy')]
                }
                if (filtri.aDataRateazione) {
                    mappaFiltri << ['aDataRateazione': filtri.aDataRateazione.format('dd/MM/yyyy')]
                }
            }
        }

        return mappaFiltri
    }

    def creaFiltriAccertamento(def filtri) {

        def mappaFiltri = creaFiltriLiquidazioni(filtri)

        mappaFiltri << ['tipoTributo': filtri.tipoTributo]
        mappaFiltri << ['tipoPratica': filtri.tipoPratica]

        mappaFiltri << ['codVia': filtri.indirizzo?.id ?: -1]
        mappaFiltri << ['daCivico': filtri.daCivico ?: -1]
        mappaFiltri << ['aCivico': filtri.aCivico ?: -1]

        if (filtri.aRuolo != 'T' && filtri.tipoPratica != 'S') {
            mappaFiltri << ['aRuolo': filtri.aRuolo]
        }

        if (filtri.flagDenuncia != 'T' && filtri.tipoPratica != 'S') {
            mappaFiltri << ['flagDenuncia': filtri.flagDenuncia]
        }

        switch (filtri.tipoTributo) {
            case 'TARSU':
                if (filtri.titoloOccupazione) {
                    mappaFiltri << ['titoloOccupazione': filtri.titoloOccupazione]
                }

                if (filtri.naturaOccupazione) {
                    mappaFiltri << ['naturaOccupazione': filtri.naturaOccupazione]
                }

                if (filtri.destinazioneUso) {
                    mappaFiltri << ['destinazioneUso': filtri.destinazioneUso]
                }

                if (filtri.assenzaEstremiCat) {
                    mappaFiltri << ['assenzaEstremiCat': filtri.assenzaEstremiCat]
                }

                if (filtri.codiceTributo) {
                    mappaFiltri << ['codiceTributo': filtri.codiceTributo.id]
                }

                mappaFiltri << ['daCategoria': filtri.daCategoria ?: -1]
                mappaFiltri << ['aCategoria': filtri.aCategoria ?: -1]

                mappaFiltri << ['daTariffa': filtri.daTariffa ?: -1]
                mappaFiltri << ['aTariffa': filtri.aTariffa ?: -1]

                mappaFiltri << ['daDataAnagrafeTributaria': filtri.daDataAnagrafeTributaria?.format('dd/MM/yyyy') ?: '01/01/1000']
                mappaFiltri << ['aDataAnagrafeTributaria': filtri.aDataAnagrafeTributaria?.format('dd/MM/yyyy') ?: '31/12/9999']

                if (filtri.tipoAttoSanzione != 'T' && filtri.tipoPratica != 'S') {
                    mappaFiltri << ['tipoAttoSanzione': filtri.tipoAttoSanzione]
                }

                if (filtri.tipoEvento != 'TUTTI' && filtri.tipoPratica != 'S') {
                    mappaFiltri << ['tipoEvento': filtri.tipoEvento]
                }

                if (filtri.daDataScadenza) {
                    mappaFiltri << ['daDataScadenza': filtri.daDataScadenza]
                }
                if (filtri.aDataScadenza) {
                    mappaFiltri << ['aDataScadenza': filtri.aDataScadenza]
                }

                break
            case ['ICI', 'TASI']:
                // Si devono impostare i default per i parametri obbligatori
                mappaFiltri << ['daCategoria': -1]
                mappaFiltri << ['aCategoria': -1]
                mappaFiltri << ['daTariffa': -1]
                mappaFiltri << ['aTariffa': -1]
                mappaFiltri << ['daDataAnagrafeTributaria': '01/01/1000']
                mappaFiltri << ['aDataAnagrafeTributaria': '31/12/9999']

                if (filtri.soloPraticheTotali) {
                    mappaFiltri << ['soloPraticheTotali': 'T']
                }

                if (filtri.tipoEvento != 'TUTTI' && filtri.tipoPratica != 'S') {
                    mappaFiltri << ['tipoEvento': filtri.tipoEvento]
                }

                if (filtri.flagPossesso != 'T') {
                    mappaFiltri << ['flagPossesso': filtri.flagPossesso]
                }

                if (filtri.tipoAttoSanzione != 'T' && filtri.tipoPratica != 'S') {
                    mappaFiltri << ['tipoAttoSanzione': filtri.tipoAttoSanzione]
                }

                if (filtri.tipoTributo == 'TASI') {
                    if (filtri.tipoRapporto != 'T') {
                        mappaFiltri << ['tipoRapporto': filtri.tipoRapporto]
                    }
                }
                break
            case ['CUNI', 'TOSAP', 'ICP']:
                // Si devono impostare i default per i parametri obbligatori
                mappaFiltri << ['daCategoria': -1]
                mappaFiltri << ['aCategoria': -1]
                mappaFiltri << ['daTariffa': -1]
                mappaFiltri << ['aTariffa': -1]
                mappaFiltri << ['daDataAnagrafeTributaria': '01/01/1000']
                mappaFiltri << ['aDataAnagrafeTributaria': '31/12/9999']

                if (filtri.tipoAttoSanzione != 'T' && filtri.tipoPratica != 'S') {
                    mappaFiltri << ['tipoAttoSanzione': filtri.tipoAttoSanzione]
                }

                if (filtri.tipoEvento != 'TUTTI' && filtri.tipoPratica != 'S') {
                    mappaFiltri << ['tipoEvento': filtri.tipoEvento]
                }

                if (filtri.soloPraticheTotali) {
                    mappaFiltri << ['soloPraticheTotali': 'T']
                }

                if (filtri.daDataScadenza) {
                    mappaFiltri << ['daDataScadenza': filtri.daDataScadenza]
                }
                if (filtri.aDataScadenza) {
                    mappaFiltri << ['aDataScadenza': filtri.aDataScadenza]
                }

                break

            default:
                // Si devono impostare i default per i parametri obbligatori
                mappaFiltri << ['daCategoria': -1]
                mappaFiltri << ['aCategoria': -1]
                mappaFiltri << ['daTariffa': -1]
                mappaFiltri << ['aTariffa': -1]
                mappaFiltri << ['daDataAnagrafeTributaria': '01/01/1000']
                mappaFiltri << ['aDataAnagrafeTributaria': '31/12/9999']

                if (filtri.tipoEvento != 'TUTTI' && filtri.tipoPratica != 'S') {
                    mappaFiltri << ['tipoEvento': filtri.tipoEvento]
                }

                if (filtri.soloPraticheTotali) {
                    mappaFiltri << ['soloPraticheTotali': 'T']
                }

                break
        }

        return mappaFiltri
    }


    def numeraPratiche(def tipoTributo, def tipoPratica,
                       def ni, def codFiscale,
                       def daAnno, def adAnno,
                       def daData, def aData,
                       def cognomeNome) {


        new Sql(dataSource).call('{call numera_pratiche(?, ?, ?, ?, ?, ?, ?, ?,?)}'
                , [
                tipoTributo, tipoPratica,
                ni, codFiscale,
                daAnno, adAnno,
                daData ? new Date(daData.getTime()) : null,
                aData ? new Date(aData.getTime()) : null,
                cognomeNome?.toUpperCase()
        ])
    }

    def dataNotifica(def tipoTributo, def tipoPratica,
                     def ni, def codFiscale,
                     def daAnno, def adAnno,
                     def daData, def aData,
                     def daNum, def aNum,
                     def dataNotifica,
                     def cognomeNome) {

        def queryParams = [
                a_ni          : -1,
                a_cod_fiscale : codFiscale ?: "",
                a_tipo_tributo: tipoTributo,
                a_tipo_pratica: tipoPratica,
                a_da_anno     : daAnno ?: 1,
                a_a_anno      : adAnno ?: 9999,
                a_da_data     : daData ? daData.format("yyyyMMdd") : "18000101",
                a_a_data      : aData ? daData.format("yyyyMMdd") : "99991231",
                a_da_num      : daNum ? (daNum as String).padLeft(15, ' ') : '0'.padLeft(15, ' '),
                a_a_num       : aNum ? (aNum as String).padLeft(15, ' ') : '9' * 15,
                a_cognome_nome: cognomeNome ?: '%'
        ]


        def sqlPraticheTrattate = """
                    select count(*) as pratiche_modificate
                      from contribuenti     cont,
                           rapporti_tributo ratr,
                           pratiche_tributo prtr,
                           soggetti         sogg
                     where cont.ni = decode(:a_ni, -1, cont.ni, :a_ni)
                       and cont.cod_fiscale = ratr.cod_fiscale
                       and upper(ratr.cod_fiscale) like decode(:a_cod_fiscale, '', ratr.cod_fiscale, upper(:a_cod_fiscale))
                       and ratr.pratica = prtr.pratica
                       and sogg.ni = cont.ni
                       and prtr.tipo_tributo = :a_tipo_tributo
                       and prtr.tipo_pratica = :a_tipo_pratica
                       and prtr.anno between :a_da_anno and :a_a_anno
                        and prtr.data between
                           to_date(:a_da_data, 'yyyymmdd') and
                           to_date(:a_a_data,  'yyyymmdd')
                       and lpad(prtr.numero, 15, ' ') between :a_da_num and :a_a_num
                       and (:a_cognome_nome is null or upper(sogg.cognome_nome_ric) like upper(:a_cognome_nome))
                       and prtr.numero is not null
                       and prtr.data_notifica is null
                     order by prtr.data, cont.cod_fiscale, prtr.anno
            """

        def numPratiche = sessionFactory.currentSession.createSQLQuery(sqlPraticheTrattate).with {

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            queryParams.each { k, v ->
                setParameter(k, v)
            }

            list()
        }[0].praticheModificate

        daNum = daNum ? (daNum as String).padLeft(15, ' ') : '0'.padLeft(15, ' ')
        aNum = aNum ? (aNum as String).padLeft(15, ' ') : '9' * 15


        Sql sql = new Sql(dataSource)
        sql.call('{call AGGIORNAMENTO_DATA_NOTIFICA(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}'
                , [
                tipoTributo, tipoPratica,
                ni, codFiscale?.toUpperCase(),
                daAnno, adAnno,
                daData ? new Timestamp(daData.getTime()) : null, aData ? new Timestamp(aData?.getTime()) : null,
                daNum, aNum,
                new Timestamp(dataNotifica.getTime()),
                cognomeNome?.toUpperCase()
        ])

        return numPratiche
    }

    def eliminaSanzioniPratica(def pratica) {
        def sql = """
                delete from sanzioni_pratica sapr
                 where sapr.pratica = ${pratica.id}
                   and sapr.cod_sanzione = (select sanz.cod_sanzione
                                              from sanzioni sanz
                                             where sanz.tipo_tributo = '${pratica.tipoTributo.tipoTributo}'
                                               and sanz.cod_sanzione = sapr.cod_sanzione
                                               and sanz.flag_imposta is null
                                               and sanz.flag_interessi is null
                                               and ((sanz.tipo_tributo = 'TASI' and
                                                   sanz.cod_sanzione not in (97, 197)) or
                                                   (sanz.tipo_tributo = 'ICI' and
                                                   sanz.cod_sanzione not in (97, 197)) or
                                                   (sanz.tipo_tributo = 'TARSU' and
                                                   sanz.cod_sanzione not in (115, 197)))

                                            )
        """

        sessionFactory.currentSession.createSQLQuery(sql).executeUpdate()
    }

    def eliminaSanzioniProcedure(def idPratica) {
        Sql sql = new Sql(dataSource)
        sql.call('{call elimina_sanz_liq_deceduti(?)}', [idPratica])
    }

    def eliminaTutteLeSanzioni(Long idPratica) {
        def sql = """
				delete from sanzioni_pratica sapr
				where sapr.pratica = ${idPratica}
        """

        sessionFactory.currentSession.createSQLQuery(sql).executeUpdate()
    }

    def hasSanzioni(Long idPratica) {

        def sql = """
            select count(*)
			from sanzioni_pratica sapr
			where sapr.pratica = ${idPratica}
		"""

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(sql)

        def nSanzioni = 0
        sqlQuery.with {
            list()
        }.each {
            nSanzioni = it
        }

        return (nSanzioni > 0)
    }

    def eliminaVersamento(def versamento) {
        def versamentoDaEliminare
        switch (versamento.getClass()) {
            case Long.class:
                versamentoDaEliminare = Versamento.get(versamento)
                break
            case VersamentoDTO:
                versamentoDaEliminare = versamento.toDomain()
                break
            case Versamento:
                versamentoDaEliminare = versamento
                break
            default:
                throw new RuntimeException("Tipo ${versamento.getClass()} non supportato.")
        }

        if (!versamentoDaEliminare) {
            throw new RuntimeException("Il versamento da eliminare non esiste.")
        }

        versamentoDaEliminare.delete(flush: true, failOnError: true)
    }

    def salvaVersamento(def versamento) {
        def versamentoDaSalvare
        switch (versamento.getClass()) {
            case VersamentoDTO:
                versamentoDaSalvare = versamento.toDomain()
                break
            case Versamento:
                versamentoDaSalvare = versamento
                break
            default:
                throw new RuntimeException("Tipo ${versamento.getClass()} non supportato.")
        }

        versamentoDaSalvare.save(flush: true, failOnError: true)
    }

    def salvaVersamenti(def versamenti) {
        versamenti.each {
            salvaVersamento(it)
        }
    }

    def elencoRuoliVersamento(def tipoTributo, def anno, def codFiscale) {

        def annoRuolo = anno ?: -1
        String sqlAnno = ""

        if (annoRuolo != -1) {
            sqlAnno = " and ruoli.anno_ruolo = :anno "
        }

        def sql = """
            select
             ruoli.ruolo "ruolo"
              from ruoli, tipi_tributo, contribuenti, soggetti
             where
               ruoli.tipo_tributo = :tipoTributo
               and tipi_tributo.tipo_tributo = ruoli.tipo_tributo
               ${sqlAnno}
               and contribuenti.cod_fiscale = :codFiscale
               and soggetti.ni = contribuenti.ni
               and exists
             (select 1
                      from ruoli_contribuente
                     where ruoli_contribuente.ruolo = ruoli.ruolo
                       and ruoli_contribuente.cod_fiscale = :codFiscale)
             order by ruoli.tipo_ruolo      asc,
                      ruoli.anno_ruolo      asc,
                      ruoli.anno_emissione  asc,
                      ruoli.progr_emissione asc,
                      ruoli.data_emissione  asc,
                      ruoli.invio_consorzio asc
        """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {

            setString('tipoTributo', tipoTributo)
            setString('codFiscale', codFiscale)

            if (annoRuolo != -1) {
                setLong('anno', anno)
            }

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            list()
        }

        def ruoli = []
        results.each { ruoli << Ruolo.get(it.ruolo).toDTO() }

        return ruoli
    }

    def elencoMotivazioni(def tipoTributo, def tipoPratica, def anno) {
        def sql = """
            select motivi_pratica.tipo_pratica "tipoPratica",
                   motivi_pratica.motivo "motivo",
                   motivi_pratica.tipo_tributo "tipoTributo",
                   motivi_pratica.sequenza "sequenza",
                   motivi_pratica.anno "anno"
              from motivi_pratica
             where (nvl(motivi_pratica.tipo_tributo, :tipoTributo) = :tipoTributo)
               and (nvl(motivi_pratica.tipo_pratica, :tipoPratica) = :tipoPratica)
               and (nvl(motivi_pratica.anno, :anno) = :anno)
             order by motivi_pratica.tipo_pratica asc

        """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setString('tipoTributo', tipoTributo)
            setString('tipoPratica', tipoPratica)
            setLong('anno', anno)

            list()
        }.collect { new MotiviPraticaDTO(it) }

        return results
    }

    def modificheSanzioni(boolean lettura, SanzioneDTO sanzione, def dataNotifica, boolean gestioneBloccate = true, boolean sanzioneMinimaSuRiduzione = false) {

        String tipoCausale = sanzione?.tipoCausale ?: ''
        Boolean scrittura = !lettura
        Boolean nonNotificata = !dataNotifica

        Boolean ridotta = sanzione?.getIsRidotta() ?: false
        Boolean nonRidottaBloccata = true
        // !(ridotta && sanzioneMinimaSuRiduzione)	// Con gestione per date il blocco modifiche non serve, per ora almeno

        def risultato = [
                modificheBloccate : scrittura && nonNotificata && (tipoCausale == 'E' && gestioneBloccate) && nonRidottaBloccata,
                modificheSbloccate: scrittura && nonNotificata && (tipoCausale == 'E' && !gestioneBloccate) && nonRidottaBloccata,
                duplica           : scrittura && nonNotificata && (tipoCausale != 'E' || !gestioneBloccate),
                elimina           : scrittura && nonNotificata && (tipoCausale != 'E' || !gestioneBloccate) && nonRidottaBloccata,
                modifica          : scrittura && nonNotificata && (tipoCausale != 'E' || !gestioneBloccate) && nonRidottaBloccata,
                modificaCausale   : scrittura && nonNotificata && tipoCausale != 'E' && nonRidottaBloccata
        ]

        return risultato
    }

    def salvaFrontespizioPratica(def pratica, def gestioneNotificheOggetto = true) {

        def creazione = pratica.id == null

        Sql sql = new Sql(dataSource)

        try {

            // La data della pratica deve essere valorizzata
            if (!pratica.data) {
                throw new RuntimeException("ORA-20999: Valore obbligatorio su Data Liquidazione\n")
            }

            if (pratica.tipoPratica == TipoPratica.V.id) {
                if (pratica.dataRiferimentoRavvedimento == null) {
                    throw new RuntimeException("ORA-20999: Valore obbligatorio su Data Pagamento\n")
                }

                /// Per i ravvedimenti TARSU la data_scadenza funge da data_scadenza_avviso per DePag
                if (pratica.tipoTributo.tipoTributo in ['TARSU']) {
                    if (pratica.dataScadenza) {
                        if (pratica.dataScadenza < pratica.dataRiferimentoRavvedimento) {
                            throw new RuntimeException("ORA-20999: Se specificata, la Scadenza avviso deve essere uguale o posteriore a Data Pagamento\n")
                        }
                    }
                }
            }

            def ruolo = inRuoloCoattivo(pratica)
            // Se a ruolo non si può eliminare la data di notifica
            if (pratica.id != null && pratica.dataNotifica == null && ruolo) {
                throw new RuntimeException("ORA-20999: Pratica in Ruolo Coattivo Numero ${ruolo.id}. Modifiche non permesse.\n")
            }

            // Nuova pratica
            if (pratica?.id == null) {
                // Se il contribuente non è indicato si da errore
                ContribuenteDTO contribuenteDTO = pratica.contribuente
                if (!contribuenteDTO.codFiscale) {
                    throw new RuntimeException("ORA-20999: Specificare contribuente\n")
                }

                // Se il contribuente indicato non è un contribuente si crea
                Contribuente contribuente = contribuenteDTO.getDomainObject()
                if (contribuente == null) {
                    contribuente = new Contribuente()
                    contribuente.soggetto = contribuenteDTO.soggetto.getDomainObject()
                    contribuente.codFiscale = contribuenteDTO.codFiscale
                    pratica.contribuente = contribuente.save(flush: true, failOnError: true).toDTO()
                }

                pratica.tipoEvento = pratica.tipoEvento ?: TipoEventoDenuncia.I
            }

            def prt = pratica.toDomain().save(flush: true, failOnError: true)

            if (creazione) {
                /// #75494 : Era per tutto 'D', non va bene - A -> 'E', per le altre -> Null
                def tipoRapporto = (prt.tipoPratica == TipoPratica.A.tipoPratica) ? 'E' : null
                (new RapportoTributo(pratica: prt, tipoRapporto: tipoRapporto, contribuente: prt.contribuente))
                        .save(flush: true, failOnError: true)
            }

            if (gestioneNotificheOggetto) {

                PraticaTributo.withNewTransaction {

                    sql.call("""{call GESTIONE_NOOG_PRATICA(?,?,?,?)}""",
                            [
                                    pratica.contribuente.codFiscale,
                                    pratica.id,
                                    pratica.dataNotifica ? new Date(pratica.dataNotifica.getTime()) : null,
                                    pratica.tipoStato?.tipoStato
                            ])
                }
            }

            return prt

        } catch (Exception e) {
            String message = ""
            if (e?.message?.startsWith("ORA-20999")) {
                throw new Application20999Error(e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n')))
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                throw new Application20999Error(e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n')))
            } else {
                throw e
            }
        }
    }

    def salvaOggettiPratica(def oggettiPratica) {
        // Salvataggio delle note su OgPr
        oggettiPratica.each {
            it.toDomain().save(flush: true, failOnError: true)
        }
    }

    def salvaOggettiContribuente(def oggettiContribuente) {
        oggettiContribuente.each {
            it.toDomain().save(flush: true, failOnError: true)
        }
    }

    def salvaSanzioniPratica(def sanzioni) {

        try {
            // Importo deve essere valorizzato
            if (sanzioni.find { it.importo == null } != null) {
                throw new RuntimeException("ORA-20999: Valore obbligatorio su 'importo'.\n")
            }

            if (sanzioni && !sanzioni.empty) {
                SanzionePratica.findAllByPratica(sanzioni[0].pratica.toDomain()).each { it.delete(flush: true, failOnError: true) }
            }

            sanzioni.each {

                def sp = it.toDomain()

                if (it.eliminato) {
                    sp.delete(flush: true, failOnError: true)
                } else {
                    if (!it.sequenza) {
                        sp.sequenza = nextSequenzaSanzioni(sp.pratica, sp.sanzione)
                    }
                    sp.utente = springSecurityService.currentUser
                    sp.seqSanz = sp.sanzione.sequenza
                    sp.save(flush: true, failOnError: true)
                }
            }
        } catch (Exception e) {
            String message = ""
            if (e?.message?.startsWith("ORA-20999")) {
                throw new Application20999Error(e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n')))
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                throw new Application20999Error(e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n')))
            } else {
                throw e
            }
        }
    }

    def salvaVersamentiPratica(def versamenti) {

        try {

            def ruolo = inRuoloCoattivo(versamenti[0].pratica)

            versamenti.each {
                def v = it.toDomain()

                v.utente = springSecurityService.currentUser?.id

                if (it.eliminato) {
                    v.delete(flush: true, failOnError: true)
                } else {

                    if (!v.tipoVersamento) {
                        v.rata = v.rata ?: 0
                    }

                    if (!v.sequenza) {
                        v.sequenza = versamentiService.getNuovaSequenzaVersamento(
                                v.contribuente.codFiscale,
                                v.tipoTributo.tipoTributo,
                                v.anno
                        )
                    }

                    // Se a ruolo il versamento deve essere associato al ruolo
                    // Controllo effettuato solo sui nuovi versamenti o versamenti clonati
                    if (it.nuovo && ruolo && ruolo.id != v.ruolo?.id) {
                        throw new RuntimeException("ORA-20999: Pagamento permesso solo con Ruolo Coattivo ${ruolo.id}.\n")
                    }

                    // Se è indicata una rata, la data di pagamento deve essere >= della data di rateazione
                    if (v.rata) {
                        if (v.dataPagamento < v.pratica.dataRateazione) {
                            throw new RuntimeException("ORA-20999: La data del versamento della rata ${v.rata} deve essere maggiore o uguale alla data di rateazione.\n")
                        }
                    }

                    v.save(flush: true, failOnError: true)
                }
            }
        } catch (Exception e) {
            String message = ""
            if (e?.message?.startsWith("ORA-20999")) {
                throw new Application20999Error(e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n')))
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                throw new Application20999Error(e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n')))
            } else {
                throw e
            }
        }
    }

    def salvaIter(def iter) {

        try {
            iter*.toDomain()*.save(flush: true, failOnError: true)
        } catch (Exception e) {
            String message = ""
            if (e?.message?.startsWith("ORA-20999")) {
                throw new Application20999Error(e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n')))
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                throw new Application20999Error(e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n')))
            } else {
                throw e
            }
        }
    }

    def salvaRateazionePratica(def pratica) {

        try {
            def erroreRate
            pratica.rate.each {
                // Verifica integrità importo rata con impostazione pratica
                if (!erroreRate) {
                    // Non son sicuro che sia sempre un RataPraticaDTO, quindi ricalcoliamo
                    BigDecimal importoRata = (it.importoCapitale ?: 0) + (it.importoInteressi ?: 0) + ((it.aggioRimodulato ? it.aggioRimodulato : it.aggio) ?: 0) +
                            ((it.dilazioneRimodulata ? it.dilazioneRimodulata : it.dilazione) ?: 0)
                    if (pratica.importoRate) {
                        if (importoRata != pratica.importoRate) {
                            erroreRate = true
                        }
                    }
                }
            }

            if (erroreRate) {
                throw new RuntimeException("ORA-20999: L'importo della rata non coincide con quota capitale + quota interessi + aggio rimodulato + dilazione rimodulata.\n")
            }

            def rateOld = rateazioneService.elencoRate(pratica)

            // Se le rate sono state eliminate
            if (pratica.rate.empty && !rateOld.empty) {
                rateOld.each {
                    it.delete(failOnError: true, flush: true)
                }
            }

            // Se sono state effettuate modifiche
            if (!pratica.rate.empty) {
                pratica.rate.each {
                    it.toDomain().save(failOnError: true, flush: true)
                }
            }

            pratica?.toDomain()?.save(failOnError: true, flush: true)
        } catch (Exception e) {
            commonService.serviceException(e)
        }
    }

    def nextSequenzaSanzioni(def pratica, def sanzione) {
        Short sequenza = 0

        Sql sql = new Sql(dataSource)
        sql.call('{call SANZIONI_PRATICA_NR(?, ?, ?, ?)}',
                [
                        pratica.id,
                        sanzione.codSanzione,
                        sanzione.sequenza,
                        Sql.NUMERIC
                ],
                { sequenza = it }
        )

        return sequenza
    }

    def elencoIter(def pratica) {
        def lista = IterPratica.findAllByPratica(pratica.toDomain()).toDTO(["stato", "tipoAtto"])
                .sort { a, b -> b.data <=> a.data ?: b.id <=> a.id }
        return lista
    }

    def eliminaPratica(def pratica) {

        if (!eliminabile(pratica.id)) {
            throw new Application20999Error("Non si hanno i diritti per eseguire l'operazione.")
        }

        try {
            PraticaTributo pt

            if (pratica instanceof PraticaTributo) {
                pt = pratica
            } else if (pratica instanceof PraticaTributoDTO) {
                pt = pratica.toDomain()
            }

            // Se sono presenti alog o deog si eliminano
            def alogDaEliminare = []
            def deogDaEliminare = []
            pt.oggettiPratica.each { op ->
                op.oggettiContribuente.each { oc ->
                    oc.aliquoteOgco.each {
                        alogDaEliminare << it
                    }
                    oc.aliquoteOgco.clear()
                    oc.detrazioniOgco.each {
                        deogDaEliminare << it
                    }
                    oc.detrazioniOgco.clear()
                }
            }
            alogDaEliminare.each {
                it.delete(flush: true)
            }
            deogDaEliminare.each {
                it.delete(flush: true)
            }

            def message = ""
            if (pt.flagDePag == 'S') {
                integrazioneDePagService.eliminaDovutoPratica(pt)
            }

            pt.delete(flush: true, failOnError: true)

            return message
        } catch (Exception e) {
            commonService.serviceException(e)
        }
    }

    def inRuoloCoattivo(def pt) {

        def sql = """
           select max(sapr.ruolo)
              from ruoli ruol, sanzioni_pratica sapr
             where ruol.ruolo = sapr.ruolo
               and ruol.specie_ruolo = 1
               and sapr.pratica = ${pt.id}
            """

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(sql)

        def ruolo
        sqlQuery.with {
            list()
        }.each {
            ruolo = it
        }

        if (ruolo) {
            return Ruolo.get(ruolo)
        }

        return null
    }

    def numeraPratica(def pratica) {
        def numero = null
        def sql = """
           select to_number(max(lpad(nvl(prtr.numero,'0'), 15, ' '))) + 1
            from pratiche_tributo prtr
                where prtr.tipo_tributo   = '${pratica.tipoTributo.tipoTributo}'
                    and prtr.tipo_pratica   in ('A','I','L','V','S')
                    and translate(prtr.numero,'a1234567890', 'a') is null
            """

        sessionFactory.currentSession.createSQLQuery(sql)
                .with { list() }
                .each { numero = it }

        pratica.numero = numero

        return pratica.toDomain().save(flush: true, failOnError: true).toDTO()
    }

    def eliminabile(def pratica) {
        def eliminabile
        Sql sql = new Sql(dataSource)
        sql.call('{? = call F_CHECK_DELETE_PRATICA(?, ?)}'
                , [
                Sql.NUMERIC,
                pratica,
                springSecurityService.currentUser.id
        ]) { eliminabile = it }
        return (eliminabile == 0)
    }

    /// Determina se il ravvedimento e' relativo a ruoli
    def isRavvedimentoSuRuoli(def pratica) {

        if (pratica instanceof PraticaTributo) {
            pratica = pratica.refresh().toDTO()
        } else if (pratica instanceof PraticaTributoDTO) {
            pratica = pratica.toDomain().refresh().toDTO()
        } else {

            throw new IllegalArgumentException("Pratica non supportata ${pratica?.class}")
        }

        return (pratica.tipoTributo.tipoTributo in ['TARSU']) && (pratica.tipoPratica == TipoPratica.V.tipoPratica) &&
                (pratica.tipoRavvedimento == 'D') && (pratica.tipoEvento == TipoEventoDenuncia.R0)
    }

    def creaRavvedimentoSuRuoli(String codFiscale, Integer anno, String tipoTributo, def tipoEvento, def dataRiferimento, def dettaglioDebiti, def dettaglioCrediti) {

        PraticaTributo pratica = null

        List<DebitoRavvedimento> debiti = []
        List<CreditoRavvedimento> crediti = []
        DebitoRavvedimento debito
        CreditoRavvedimento credito

        def praticaId = null
        def contatore = 0

        if (!(tipoTributo in ['TARSU'])) {
            throw new Exception("Tipo tributo ${tipoTributo} non supportato !")
        }

        String tipoRavvedimento = 'D'

        try {

            pratica = creaPraticaRavvedimento(codFiscale, anno, tipoTributo, tipoEvento, tipoRavvedimento, dataRiferimento)

            dettaglioDebiti.each {
                debito = creaDebitoRavvedimento(pratica, it)
                debiti << debito
            }

            dettaglioCrediti.each {
                credito = creaCreditoRavvedimento(pratica, it)
                crediti << credito
            }

            praticaId = pratica.id

            contatore++

            def session = sessionFactory.currentSession
            session.flush()
            session.clear()
        } catch (Exception e) {

            debiti.clear()
            crediti.clear()

            if (pratica) {
                pratica.delete(flush: true, failOnError: true)
            }
            commonService.serviceException(e)
        }

        return ['pratica': praticaId, 'contatore': contatore]
    }

    def creaPraticaRavvedimento(String codFiscale, Integer anno, String tipoTributo, def tipoEvento, String tipoRavvedimento, def dataRiferimento) {

        PraticaTributo pratica = null
        Contribuente contribuente

        try {
            contribuente = contribuentiService.ricavaContribuente(codFiscale)

            pratica = new PraticaTributo()
            pratica.anno = anno

            pratica.tipoTributo = TipoTributo.get(tipoTributo)
            pratica.tipoPratica = TipoPratica.V.tipoPratica
            pratica.tipoEvento = tipoEvento
            pratica.tipoRavvedimento = tipoRavvedimento

            RapportoTributo ratr = new RapportoTributo()
            ratr.tipoRapporto = null
            ratr.contribuente = contribuente
            pratica.addToRapportiTributo(ratr)

            pratica.contribuente = contribuente

            pratica.data = getDataOdierna(false)
            pratica.dataRiferimentoRavvedimento = dataRiferimento
            pratica.dataScadenza = dataRiferimento

            pratica.note = null
            pratica.motivo = null
            pratica.numero = null

            pratica.versamenti = []
            pratica.sanzioniPratica = []
            pratica.rate = []
            pratica.iter = []

            pratica.save(failOnError: true, flush: true)

            numeraPratica(pratica.toDTO())
        } catch (Exception e) {
            throw e
        }

        return pratica
    }

    def creaDebitoRavvedimento(PraticaTributo pratica, def dettagli) {

        DebitoRavvedimento debito

        def maggiorazioneTares
        def versato

        try {
            debito = new DebitoRavvedimento()

            debito.pratica = pratica
            debito.ruolo = dettagli.ruolo

            dettagli.rate.each { rata ->

                maggiorazioneTares = rata.maggTARES

                versato = ((rata.superato) || (!rata.scaduta)) ? null : rata.versato

                switch (rata.rata) {
                    case 0:
                    case 1:
                        debito.scadenzaPrimaRata = rata.scadenzaRataDate
                        debito.importoPrimaRata = rata.importo
                        debito.versatoPrimaRata = versato
                        debito.maggiorazioneTaresPrimaRata = maggiorazioneTares
                        break;
                    case 2:
                        debito.scadenzaRata2 = rata.scadenzaRataDate
                        debito.importoRata2 = rata.importo
                        debito.versatoRata2 = versato
                        debito.maggiorazioneTaresRata2 = maggiorazioneTares
                        break;
                    case 3:
                        debito.scadenzaRata3 = rata.scadenzaRataDate
                        debito.importoRata3 = rata.importo
                        debito.versatoRata3 = versato
                        debito.maggiorazioneTaresRata3 = maggiorazioneTares
                        break;
                    case 4:
                        debito.scadenzaRata4 = rata.scadenzaRataDate
                        debito.importoRata4 = rata.importo
                        debito.versatoRata4 = versato
                        debito.maggiorazioneTaresRata4 = maggiorazioneTares
                        break;
                }
            }

            debito.note = null

            debito.utente = springSecurityService.currentUser?.id

            debito.save(failOnError: true, flush: true)
        } catch (Exception e) {
            throw e
        }

        return debito
    }

    def creaCreditoRavvedimento(PraticaTributo pratica, def dettagli) {

        CreditoRavvedimento credito

        try {
            credito = new CreditoRavvedimento()

            credito.pratica = pratica

            credito.sequenza = dettagli.versamentoId

            credito.descrizione = dettagli.tipoVersamento
            credito.anno = pratica.anno
            credito.dataPagamento = dettagli.dataPagamento
            credito.rata = dettagli.rata
            credito.ruolo = dettagli.ruolo
            credito.importoVersato = dettagli.importoVersato
            credito.sanzioni = dettagli.totSanzioni
            credito.interessi = dettagli.totInteressi
            credito.altro = dettagli.totAltro

            credito.codIUV = dettagli.IUV

            credito.note = dettagli.ravvNote

            credito.utente = springSecurityService.currentUser?.id

            credito.save(failOnError: true, flush: true)
        } catch (Exception e) {
            throw e
        }

        return credito
    }

    def creaRavvedimento(def codFiscale, def anno, def dataVersamento, def tipoVersamento, def tipologia, def tipoTributo, def idPratica = null) {

        try {

            def pratica = null

            Sql sql = new Sql(dataSource)
            sql.call('{call crea_ravvedimento(?, ?, ?, ?, ?, ?, ?, ?)}'
                    , [
                    codFiscale,
                    anno,
                    new Date(dataVersamento.getTime()),
                    tipoVersamento,
                    tipologia == 'D' ? 'O' : null,
                    springSecurityService.currentUser.id,
                    tipoTributo,
                    idPratica ?: Sql.NUMERIC

            ], { res ->

                pratica = res
            })

            return pratica
        } catch (Exception e) {
            commonService.serviceException(e)
        }
    }

    def creaRavvedimenti(def codFiscale, def daAnno, def adAnno, def dataVersamento,
                         def tipoVersamento, def tipologia, def tipoTributo, def rata,
                         def idPratica = null, def gruppoTributo = null) {

        //se anno a non è specificato si esegue il calcolo su anno da
        adAnno = adAnno ?: daAnno

        def pratica
        def contatore = 0

        for (int anno in daAnno..adAnno) {

            try {

                Sql sql = new Sql(dataSource)
                sql.call('{call crea_ravvedimento(?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?)}'
                        , [
                        codFiscale,
                        anno,
                        new Date(dataVersamento.getTime()),
                        tipoVersamento,
                        tipologia == 'D' ? 'O' : null,
                        springSecurityService.currentUser.id,
                        tipoTributo,
                        idPratica ?: Sql.NUMERIC,
                        null,
                        rata,
                        gruppoTributo as String
                ], { res -> pratica = res })

            } catch (Exception e) {
                commonService.serviceException(e)
            }
            contatore++
        }

        return ['pratica': pratica, 'contatore': contatore]
    }

    def cambiaTipoVersamentoRavvedimento(def versamento, def tipoVersamento) {

        def messaggio = ""
        try {

            Sql sql = new Sql(dataSource)
            sql.call('{call CREA_RAVVEDIMENTO_DA_VERS(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}'
                    , [
                    versamento.contribuente.codFiscale,
                    versamento.anno,
                    new Date(versamento.dataPagamento.getTime()),
                    tipoVersamento as String,
                    versamento.pratica.tipoRavvedimento,
                    springSecurityService.currentUser.id,
                    versamento.tipoTributo.tipoTributo,
                    versamento.sequenza,
                    versamento.importoVersato,
                    versamento.pratica.id,
                    Sql.VARCHAR

            ], { res ->

                log.info "Risposta da CREA_RAVVEDIMENTO_DA_VERS: ${res}"
                messaggio = res
            })

        } catch (Exception e) {
            commonService.serviceException(e)
        }

        return messaggio
    }

    def calcolaSanzioniRavvedimento(def idPratica, def tipoVersamento = null) {

        try {
            def pratica = PraticaTributo.get(idPratica)

            def dataVersamento = pratica.dataRiferimentoRavvedimento ?: pratica.data
            def tipologia = pratica.tipoRavvedimento
            def tipoTributo = pratica.tipoTributo.tipoTributo
            tipoVersamento = tipoVersamento ?: pratica.tipoEvento.tipoEventoDenuncia

            String flagInfrazione;

            Sql sql = new Sql(dataSource)

            if (tipoTributo in ['TARSU']) {
                switch (tipologia) {
                    case 'D':
                        if (tipoVersamento == '0') {
                            flagInfrazione = 'R'
                        } else {
                            flagInfrazione = 'O'    /// valore legacy, non è chiaro se ancora usato per TARSU
                        }
                        break
                    default:
                        flagInfrazione = null
                        break
                }

                log.info "Esecuzione: CALCOLO_SANZIONI_RAOP_${tipoTributo}($idPratica, $dataVersamento, ${springSecurityService.currentUser.id}, $flagInfrazione)"

                /// Per motivi storici TARSU usa quattro parametri (Compatibilità TR4), gli altri tributi cinque
                sql.call("{call CALCOLO_SANZIONI_RAOP_${tipoTributo}(?, ?, ?, ?)}",
                        [
                                idPratica,
                                new Date(dataVersamento.getTime()),
                                springSecurityService.currentUser.id,
                                flagInfrazione
                        ]
                )
            } else {
                flagInfrazione = tipologia == 'D' ? 'O' : null

                log.info "Esecuzione: CALCOLO_SANZIONI_RAOP_${tipoTributo}($idPratica, $tipoVersamento, $dataVersamento, ${springSecurityService.currentUser.id}, $flagInfrazione)"
                sql.call("{call CALCOLO_SANZIONI_RAOP_${tipoTributo}(?, ?, ?, ?, ?)}",
                        [
                                idPratica,
                                tipoVersamento,
                                new Date(dataVersamento.getTime()),
                                springSecurityService.currentUser.id,
                                flagInfrazione
                        ]
                )
            }
        } catch (Exception e) {
            commonService.serviceException(e)
        }
    }

    // Carica i dettagli dei ravvedimenti per l'anno ed il CF specificato ai fini del calcolo del ravvedimento
    def getDettagliRuoliPerRavvedimento(def anno, String codFiscale) {

        def filtri = [:]

        filtri << ['tipoTributo': 'TARSU']

        filtri << ['anno': anno]
        filtri << ['codFiscale': codFiscale]

        String sql = """
                  select
                    ruol.ruolo,
                    ruol.anno_ruolo,
                    ruol.specie_ruolo,
                    ruol.tipo_ruolo,
                    ruol.scadenza_prima_rata,
                    ruol.scadenza_rata_2,
                    ruol.scadenza_rata_3,
                    ruol.scadenza_rata_4,
                    ruol.capitalizzazione_prima_rata,
                    ruol.capitalizzazione_rata_2,
                    ruol.capitalizzazione_rata_3,
                    ruol.capitalizzazione_rata_4,
                    ruol.scadenza_rata_unica,
                    ruol.tipo_emissione,
                    ruol.data_emissione,
                    ruol.flag_depag,
                    --
                    f_get_ultimo_ruolo(dett.cod_fiscale,ruol.anno_ruolo,ruol.tipo_tributo,'T','S','S',0) as ruolo_totale,
                    --
                    f_calcolo_rata_tarsu(dett.cod_fiscale,ruol.ruolo,ruol.rate,dett.rata,'Y','') as f24_dovuto,
                    f_calcolo_rata_tarsu(dett.cod_fiscale,ruol.ruolo,ruol.rate,dett.rata,'X','') as f24_residuo,
                    --
                    -- In questi casi tocca affidarci al vecchio metodo
                    f_calcolo_rata_rc_tarsu(dett.cod_fiscale,ruol.ruolo,ruol.rate,dett.rata,'R','') as magg_tares_rata,
                    --
                    f_sbilancio_tares(dett.cod_fiscale,ruol.ruolo,0,0,'S') as sbilancio_ruolo,
                    f_sbilancio_tares(dett.cod_fiscale,ruol.ruolo,dett.rata,0,'S') as sbilancio_rata,
                    --
                    f_sbilancio_tares(dett.cod_fiscale,ruol.ruolo,0,2,'TG') as magg_tares_totale,
                    f_sbilancio_tares(dett.cod_fiscale,ruol.ruolo,dett.rata,2,'TG') as magg_tares,
                    --
                    dett.rata,
                    dett.scadenza_rata,
                    dett.capitalizzazione_rata,
                    dett.cod_fiscale,
                    --
                    sum(dett.importo_ruolo) importo_ruolo,
                    max(nvl(eccd.importo,0)) importo_ecc,
                    max(nvl(sgra.importo_lordo,0)) importo_sgravi,
                    max(nvl(sgra.maggiorazione_tares,0)) tares_sgravi,
                    --
                    sum(dett.imposta) imposta,
                    sum(dett.add_eca) add_eca,
                    sum(dett.magg_eca) magg_eca,
                  --sum(dett.magg_tares) as magg_tares,
                    sum(dett.add_pro) add_pro,
                    sum(dett.iva) iva,
                    --
                    sum(dett.imposta_ogim) imposta_ogim,
                    sum(dett.versato_ogim) versato_ogim,
                    sum(dett.add_eca_ogim) add_eca_ogim,
                    sum(dett.magg_eca_ogim) magg_eca_ogim,
                    sum(dett.magg_tares_ogim) magg_tares_ogim,
                    sum(dett.add_pro_ogim) add_pro_ogim,
                    sum(dett.iva_ogim) iva_ogim
                  from
                  (select
                    ruol.ruolo,
                    ruol.anno_ruolo,
                    ruol.specie_ruolo,
                    ruol.tipo_ruolo,
                    ruol.tipo_tributo,
                    ruol.rate,
                    ruol.scadenza_prima_rata,
                    ruol.scadenza_rata_2,
                    ruol.scadenza_rata_3,
                    ruol.scadenza_rata_4,
                    nvl(ruol.scadenza_rata_unica,ruol.scadenza_prima_rata) capitalizzazione_prima_rata,
                    nvl(ruol.scadenza_rata_unica,ruol.scadenza_rata_2) capitalizzazione_rata_2,
                    nvl(ruol.scadenza_rata_unica,ruol.scadenza_rata_3) capitalizzazione_rata_3,
                    nvl(ruol.scadenza_rata_unica,ruol.scadenza_rata_4) capitalizzazione_rata_4,
                    ruol.scadenza_rata_unica,
                    ruol.tipo_emissione,
                    ruol.data_emissione,
                    ruol.flag_depag
                  from ruoli ruol) ruol,
                  (select
                    ruol.ruolo,
                    ruco.cod_fiscale,
                    --
                    ruco.importo importo_ruolo,
                    --
                    raim.rata,
                    raim.imposta,
                    raim.imposta_round,
                    nvl(raim.addizionale_eca,0) add_eca,
                    nvl(raim.maggiorazione_eca,0) magg_eca,
                  --nvl(raim.maggiorazione_tares,0) as magg_tares,
                    nvl(raim.addizionale_pro,0) add_pro,
                    nvl(raim.iva,0) iva,
                    --
                    decode(raim.rata,1,ruol.scadenza_prima_rata,
                                     2,ruol.scadenza_rata_2,
                                     3,ruol.scadenza_rata_3,
                                     4,ruol.scadenza_rata_4,
                                     ruol.scadenza_prima_rata) scadenza_rata,
                    --
                    decode(raim.rata,1,nvl(ruol.scadenza_rata_unica,ruol.scadenza_prima_rata),
                                     2,nvl(ruol.scadenza_rata_unica,ruol.scadenza_rata_2),
                                     3,nvl(ruol.scadenza_rata_unica,ruol.scadenza_rata_3),
                                     4,nvl(ruol.scadenza_rata_unica,ruol.scadenza_rata_4),
                                     ruol.scadenza_prima_rata) capitalizzazione_rata,
                    --
                    nvl(ogim.imposta,0) imposta_ogim,
                    nvl(ogim.addizionale_eca,0) add_eca_ogim,
                    nvl(ogim.maggiorazione_eca,0) magg_eca_ogim,
                    nvl(ogim.maggiorazione_tares,0) magg_tares_ogim,
                    nvl(ogim.addizionale_pro,0) add_pro_ogim,
                    nvl(ogim.iva,0) iva_ogim,
                    nvl(ogim.importo_versato,0) versato_ogim,
                    --
                    ogim.oggetto_pratica,
                    ogim.oggetto_imposta,
                    raim.rata_imposta
                  from
                    ruoli_contribuente ruco,
                    ruoli ruol,
                    oggetti_imposta ogim,
                    rate_imposta raim
                 where ruol.tipo_tributo = :tipoTributo
                   and ruol.anno_ruolo = :anno
                   and ruol.invio_consorzio is not null
                   and ruol.ruolo = ruco.ruolo
                   and ruco.cod_fiscale like :codFiscale
                   and ruco.oggetto_imposta = ogim.oggetto_imposta
                   and ogim.ruolo = ruco.ruolo
                   and ogim.oggetto_imposta = raim.oggetto_imposta (+)
                   ) dett,
                   (select ruec.ruolo,
                           ruec.cod_fiscale,
                           sum(importo_ruolo) as importo
                      from ruoli_eccedenze ruec
                     where ruec.cod_fiscale like :codFiscale
                     group by
                           ruec.ruolo,
                           ruec.cod_fiscale
                   ) eccd,
                   (select
                     sgra.ruolo
                    ,sgra.cod_fiscale
                    ,sum(nvl(sgra.importo, 0)) importo_lordo
                    ,sum(nvl(sgra.addizionale_pro,0)) addizionale_pro
                    ,sum(nvl(sgra.maggiorazione_tares,0)) maggiorazione_tares
                   from
                    sgravi sgra,
                    ruoli ruol
                  where ruol.anno_ruolo = :anno
                    and sgra.motivo_sgravio != 99
                    and sgra.cod_fiscale like :codFiscale
                    and sgra.ruolo = ruol.ruolo
                   group by
                    sgra.ruolo,
                    sgra.cod_fiscale
                  ) sgra
                 where dett.ruolo = ruol.ruolo
                   and dett.ruolo = sgra.ruolo(+)
                   and dett.cod_fiscale = sgra.cod_fiscale(+)
                   and dett.ruolo = eccd.ruolo(+)
                   and dett.cod_fiscale = eccd.cod_fiscale(+)
                  group by 
                    ruol.ruolo,
                    ruol.anno_ruolo,
                    ruol.specie_ruolo,
                    ruol.tipo_ruolo,
                    ruol.scadenza_prima_rata,
                    ruol.scadenza_rata_2,
                    ruol.scadenza_rata_3,
                    ruol.scadenza_rata_4,
                    ruol.capitalizzazione_prima_rata,
                    ruol.capitalizzazione_rata_2,
                    ruol.capitalizzazione_rata_3,
                    ruol.capitalizzazione_rata_4,
                    ruol.tipo_emissione,
                    ruol.data_emissione,
                    ruol.flag_depag,
                    ruol.scadenza_rata_unica,
                    dett.capitalizzazione_rata,
                    f_get_ultimo_ruolo(dett.cod_fiscale,ruol.anno_ruolo,ruol.tipo_tributo,'T','S','S',0),
                    f_calcolo_rata_tarsu(dett.cod_fiscale,ruol.ruolo,ruol.rate,dett.rata,'Y',''),
                    f_calcolo_rata_tarsu(dett.cod_fiscale,ruol.ruolo,ruol.rate,dett.rata,'X',''),
                    f_calcolo_rata_rc_tarsu(dett.cod_fiscale,ruol.ruolo,ruol.rate,dett.rata,'R',''),
                    dett.cod_fiscale,
                    dett.rata,
                    dett.scadenza_rata
                  order by
                    ruol.anno_ruolo,
                    ruol.specie_ruolo,
                    ruol.tipo_ruolo,
                    ruol.tipo_emissione,
                    dett.rata
		"""

        def results = eseguiQuery(sql, filtri, null, true)

        def dettagli = []

        results.each {

            def dettaglio = [:]

            dettaglio.ruolo = it['RUOLO'] as Long
            dettaglio.codFiscale = it['COD_FISCALE']

            dettaglio.annoRuolo = it['ANNO_RUOLO'] as Short
            dettaglio.specieRuolo = it['SPECIE_RUOLO'] as Short
            dettaglio.tipoRuolo = it['TIPO_RUOLO'] as Short
            dettaglio.dataScadenzaRata1 = it['SCADENZA_PRIMA_RATA'] as JavaDate
            dettaglio.dataScadenzaRata2 = it['SCADENZA_RATA_2'] as JavaDate
            dettaglio.dataScadenzaRata3 = it['SCADENZA_RATA_3'] as JavaDate
            dettaglio.dataScadenzaRata4 = it['SCADENZA_RATA_4'] as JavaDate
            dettaglio.capitalizzazioneRata1 = it['CAPITALIZZAZIONE_PRIMA_RATA'] as JavaDate
            dettaglio.capitalizzazioneRata2 = it['CAPITALIZZAZIONE_RATA_2'] as JavaDate
            dettaglio.capitalizzazioneRata3 = it['CAPITALIZZAZIONE_RATA_3'] as JavaDate
            dettaglio.capitalizzazioneRata4 = it['CAPITALIZZAZIONE_RATA_4'] as JavaDate
            dettaglio.tipoEmissione = it['TIPO_EMISSIONE'] as String
            dettaglio.dataEmissione = it['DATA_EMISSIONE'] as JavaDate
            dettaglio.flagDepag = it['FLAG_DEPAG'] as String
            dettaglio.scadenzaRataUnica = it['SCADENZA_RATA_UNICA'] as JavaDate

            dettaglio.ruoloTotale = it['RUOLO_TOTALE'] as Long

            dettaglio.importoRuolo = it['IMPORTO_RUOLO']
            dettaglio.importoEcc = it['IMPORTO_ECC']

            dettaglio.f24Dovuto = it['F24_DOVUTO']
            dettaglio.f24Residuo = it['F24_RESIDUO']

            dettaglio.sbilancioRuolo = it['SBILANCIO_RUOLO']
            dettaglio.sbilancioRata = it['SBILANCIO_RATA']

            dettaglio.rata = it['RATA'] as Short
            dettaglio.scadenzaRata = it['SCADENZA_RATA'] as JavaDate
            dettaglio.capitalizzazioneRata = it['CAPITALIZZAZIONE_RATA'] as JavaDate

            dettaglio.imposta = it['IMPOSTA']
            dettaglio.addECA = it['ADD_ECA']
            dettaglio.maggECA = it['MAGG_ECA']
            dettaglio.maggTARES = it['MAGG_TARES']
            dettaglio.addPro = it['ADD_PRO']
            dettaglio.iva = it['IVA']

            dettaglio.maggTARESTotale = it['MAGG_TARES_TOTALE']

            dettaglio.maggTARESRata = it['MAGG_TARES_RATA']

            dettaglio.importoSgravi = it['IMPORTO_SGRAVI']
            dettaglio.sgraviTARES = it['TARES_SGRAVI']

            dettaglio.impostaOgim = it['IMPOSTA_OGIM']
            dettaglio.versatoOgim = it['VERSATO_OGIM']
            dettaglio.addECAOgim = it['ADD_ECA_OGIM']
            dettaglio.maggECAOgim = it['MAGG_ECA_OGIM']
            dettaglio.maggTARESOgim = it['MAGG_TARES_OGIM']
            dettaglio.addProOgim = it['ADD_PRO_OGIM']
            dettaglio.ivaOgim = it['IVA_OGIM']

            dettagli << dettaglio
        }

        /// Ricompone i dettagli e crea la struttura per ruolo
        def ruoli = [
        ]

        Long ruoloId = 1
        Long rataId = 1

        def today = Calendar.getInstance().getTime()
        Boolean superato

        dettagli.each {

            def dettaglio = it

            def ruolo = ruoli.find { it.ruolo == dettaglio.ruolo && it.codFiscale == dettaglio.codFiscale }

            if (ruolo == null) {

                ruolo = [
                        ruoloId              : ruoloId++,
                        codFiscale           : dettaglio.codFiscale,
                        ruolo                : dettaglio.ruolo,
                        annoRuolo            : dettaglio.annoRuolo,
                        specieRuolo          : dettaglio.specieRuolo,
                        tipoRuolo            : dettaglio.tipoRuolo,
                        dataScadenzaRata1    : dettaglio.dataScadenzaRata1,
                        dataScadenzaRata2    : dettaglio.dataScadenzaRata2,
                        dataScadenzaRata3    : dettaglio.dataScadenzaRata3,
                        dataScadenzaRata4    : dettaglio.dataScadenzaRata4,
                        capitalizzazioneRata1: dettaglio.capitalizzazioneRata1,
                        capitalizzazioneRata2: dettaglio.capitalizzazioneRata2,
                        capitalizzazioneRata3: dettaglio.capitalizzazioneRata3,
                        capitalizzazioneRata4: dettaglio.capitalizzazioneRata4,
                        scadenzaRataUnica    : dettaglio.scadenzaRataUnica,
                        tipoEmissione        : dettaglio.tipoEmissione,
                        dataEmissione        : dettaglio.dataEmissione,
                        flagDepag            : dettaglio.flagDepag,
                        importoRuolo         : dettaglio.importoRuolo,
                        importoEcc           : dettaglio.importoEcc,
                        maggTARES            : 0,                       // Calcolato dopo come somma delle rate
                        importoSgravi        : dettaglio.importoSgravi,
                        sgraviTARES          : dettaglio.sgraviTARES,
                        impostaOgim          : dettaglio.impostaOgim,
                        versatoOgim          : dettaglio.versatoOgim,
                        addECAOgim           : dettaglio.addECAOgim,
                        maggECAOgim          : dettaglio.maggECAOgim,
                        maggTARESOgim        : dettaglio.maggTARESOgim,
                        addProOgim           : dettaglio.addProOgim,
                        ivaOgim              : dettaglio.ivaOgim,
                        //
                        ruoloTotale          : dettaglio.ruoloTotale,
                        //
                        sbilancioRuolo       : dettaglio.sbilancioRuolo,
                        maggTARESTotale      : dettaglio.maggTARESTotale,
                        //
                        rate                 : []
                ]

                ruoli << ruolo
            }

            superato = ((ruolo.ruoloTotale) && (ruolo.ruoloTotale != ruolo.ruolo))

            def rata = [
                    rataId              : rataId++,
                    rata                : dettaglio.rata,
                    scadenzaRataDate    : dettaglio.scadenzaRata,
                    scadenzaRata        : dettaglio.scadenzaRata?.format("dd/MM/yyyy") ?: '',
                    capitalizzazioneDate: dettaglio.capitalizzazioneRata,
                    capitalizzazione    : dettaglio.capitalizzazioneRata?.format("dd/MM/yyyy") ?: '',
                    importo             : null,
                    imposta             : dettaglio.imposta,
                    addECA              : dettaglio.addECA,
                    maggECA             : dettaglio.maggECA,
                    addPro              : dettaglio.addPro,
                    iva                 : dettaglio.iva,
                    //
                    maggTARESTotale     : dettaglio.maggTARESTotale,
                    maggTARES           : dettaglio.maggTARES,
                    //
                    maggTARESRata       : dettaglio.maggTARESRata,
                    //
                    f24Dovuto           : dettaglio.f24Dovuto,
                    f24Residuo          : dettaglio.f24Residuo,
                    //
                    sbilancioRuolo      : dettaglio.sbilancioRuolo,
                    sbilancioRata       : dettaglio.sbilancioRata,
                    //
                    superato            : superato,
                    //
                    versato             : 0,
                    versatoDichiarato   : null,
                    residuo             : null,
                    //
                    fissato             : 0
            ]

            rata.importo = (rata.imposta ?: 0) + (rata.addECA ?: 0) + (rata.maggECA ?: 0) + (rata.addPro ?: 0) + (rata.iva ?: 0) + (rata.maggTARES ?: 0)
            rata.scaduta = rata.scadenzaRataDate < today

            ruolo.rate << rata
        }

        /// Completa il calcolo rate quindi applica arrotondamenti
        ruoli.each { ruolo ->

            def numRate = ruolo.rate.size

            /// Sistema importo TARES Rata
            for (rata in ruolo.rate) {

                if ((ruolo.maggTARESTotale ?: 0) != 0) {
                    /// Nuovo metodo    : ricavato mediante f_sbilancio_tares direttamente dai raim
                //  rata.maggTARES = rata.maggTARES         /// Già impostato
                }
                else {
                    /// Vecchio metodo  : ricavato mediante f_calcolo_rata_rc_tarsu mediante stima
                    rata.maggTARES = rata.maggTARESRata     /// Usa il valore stimato
                }
            }

            /// Metodo pre TEFA o con DePag
            /// - Totale unico arrotondato, tolti gli sgravi, diviso ed arrotondato con l'algoritmo storico'
            BigDecimal importoRuolo = (ruolo.importoRuolo as BigDecimal) + (ruolo.importoEcc as BigDecimal)
            importoRuolo = importoRuolo.setScale(0, RoundingMode.HALF_UP)

            BigDecimal importoSgravi = (ruolo.importoSgravi as BigDecimal).setScale(0, RoundingMode.HALF_UP)
            BigDecimal sbilancioRuolo = (ruolo.sbilancioRuolo as BigDecimal).setScale(0, RoundingMode.HALF_UP)
            def totaleLordo = importoRuolo - importoSgravi - sbilancioRuolo

            for (rata in ruolo.rate) {

                rata.importoNoRound = rata.importo

                rata.importo = rateazioneService.determinaRata(totaleLordo, rata.rata, numRate, 0);
                rata.importo += rata.sbilancioRata
            }

            /// Metodo Post TEFA e Senza DePag
            /// - Elaborazione separate per TEFA, usa i valori ricavati dalle funzioni F24 (stesse della stampa)

            if ((ruolo.flagDepag == null) && (ruolo.annoRuolo >= 2021)) {

                for (rata in ruolo.rate) {

                    rata.importoConDepag = rata.importo

                    rata.importo = rata.f24Dovuto ?: 0
                }
            }
        }

        ruoli.each { ruolo ->
            /// Sistema gli importi intermedi
            for (rata in ruolo.rate) {
                rata.residuo = rata.importo
            }

            /// Sistemazione finale dati
            ruolo.maggTARES = ruolo.rate.sum { it.maggTARES ?: 0 }

            ruolo.descrizione = creaDescrizioneRuolo(ruolo)
        }

        return ruoli
    }

    /// Carica il dovuto del ruolo per il CF leggendolo dalla banca dati depag
    def getDovutiRuoloDaDepag(Long ruoloId, String codFiscale) {

        def dovuti = []

        def dePagAbilitato = integrazioneDePagService.dePagAbilitato()

        if (dePagAbilitato) {

            def dovutiRuolo = integrazioneDePagService.determinaDovutiRuolo(codFiscale, ruoloId)

            dovutiRuolo.each {

                def dovuto = [:]

                dovuto.idBack = it['IDBACK']
                dovuto.azione = it['AZIONE']
                dovuto.dataScadenza = it['DATA_SCADENZA']
                dovuto.rata = it['RATA_NUMERO']
                dovuto.dovuto = it['IMPORTO_DOVUTO']

                dovuti << dovuto
            }
        }

        return dovuti
    }

    // Carica i dettagli dei crediti per l'anno ed il CF specificato ai fini del calcolo del ravvedimento
    def getCreditiPerRavvedimento(def anno, String codFiscale) {

        def filtri = [:]

        filtri << ['tipoTributo': 'TARSU']
        filtri << ['anno': anno]
        filtri << ['codFiscale': codFiscale]

        String sql = """
					select
							'Versamento' as tipo_versamento,
							vers.data_pagamento,
							vers.ruolo,
							vers.rata,
							vers.importo_versato,
							vers.imposta,
							vers.sanzioni_1,
							vers.sanzioni_2,
							vers.interessi,
							vers.addizionale_pro,
							vers.sanzioni_add_pro,
							vers.interessi_add_pro,
							vers.spese_spedizione,
							vers.spese_mora,
							vers.idback,
							vers.note,
                            null as ravv_lordo,
                            null as ravv_lordo_rid,
                            null as ravv_imp_sanz,
                            null as ravv_imp_sanz_rid,
                            null as ravv_interessi,
                            null as ravv_spese
						from
							versamenti vers
						where
							vers.tipo_tributo||'' = :tipoTributo
						 and vers.anno = :anno
						 and vers.cod_fiscale = :codFiscale
					     and vers.pratica is null
					union
					select
							'Versamento su Ravv.Op.' as tipo_versamento,
							vers.data_pagamento,
							vers.ruolo,
							vers.rata,
							vers.importo_versato,
							vers.imposta,
							vers.sanzioni_1,
							vers.sanzioni_2,
							vers.interessi,
							vers.addizionale_pro,
							vers.sanzioni_add_pro,
							vers.interessi_add_pro,
							vers.spese_spedizione,
							vers.spese_mora,
							vers.idback,
							vers.note,
                            case when nvl(vers.rata,0) = 0 then
                                rvdt.imp_lordo
                            else
                                rvrt.imp_lordo
                            end as ravv_lordo,
                            case when nvl(vers.rata,0) = 0 then
                                rvdt.imp_lordo_rid
                            else
                                rvrt.imp_lordo_rid
                            end as ravv_lordo_rid,
                            case when nvl(vers.rata,0) = 0 then
                                rvdt.imp_sanz
                            else
                                rvrt.imp_sanz
                            end as ravv_imp_sanz,
                            case when nvl(vers.rata,0) = 0 then
                                rvdt.imp_sanz_rid
                            else
                                rvrt.imp_sanz_rid
                            end as ravv_imp_sanz_rid,
                            case when nvl(vers.rata,0) = 0 then
                                rvdt.imp_interessi
                            else
                                rvrt.imp_interessi
                            end as ravv_interessi,
                            case when nvl(vers.rata,0) = 0 then
                                rvdt.imp_spese
                            else
                                rvrt.imp_spese
                            end as ravv_spese
						from
							versamenti vers,
							pratiche_tributo prtr,
                            (select prtr.pratica,
                                  f_importo_acc_lordo(prtr.pratica,'N') as IMP_LORDO,
                                  f_importo_acc_lordo(prtr.pratica,'S') as IMP_LORDO_RID,
                                  f_importi_acc(prtr.pratica,'N','SANZIONI') as IMP_SANZ,
                                  f_importi_acc(prtr.pratica,'S','SANZIONI') as IMP_SANZ_RID,
                                  f_importi_acc(prtr.pratica,'N','INTERESSI') as IMP_INTERESSI,
                                  f_importi_acc(prtr.pratica,'N','SPESE') as IMP_SPESE
                            from
                                  pratiche_tributo prtr
                            where
                                 prtr.cod_fiscale = :codFiscale
                             and prtr.anno = :anno
                             and prtr.tipo_pratica ='V') rvdt,
                            (select prtr.pratica,
                                    rtpt.rata,
	                                rtpt.importo_arr as IMP_LORDO,
	                                rtpt.importo_arr as IMP_LORDO_RID,
                            -- Manca la scomposizione dei parziali per rata (RV 2024/02/28) #62142
	                                0 as IMP_SANZ,
	                                0 as IMP_SANZ_RID,
	                                0 as IMP_INTERESSI,
	                                0 as IMP_SPESE
	                        --      rtpt.oneri as IMP_SPESE
                            from
	                                pratiche_tributo prtr,
	                                rate_pratica rtpt
                            where
	                                prtr.cod_fiscale = :codFiscale
                                and prtr.anno = :anno
                                and prtr.tipo_pratica ='V'
                                and prtr.pratica = rtpt.pratica) rvrt
						where
							 vers.tipo_tributo||'' = :tipoTributo
						 and vers.anno = :anno
						 and vers.cod_fiscale = :codFiscale
						 and vers.pratica = prtr.pratica 
						 and prtr.tipo_pratica = 'V'
                         and prtr.pratica = rvdt.pratica (+)
                         and vers.pratica = rvrt.pratica (+)
                         and vers.rata = rvrt.rata (+)
		"""

        def results = eseguiQuery(sql, filtri, null, true)

        def versamenti = []

        String IUV
        String note
        int iuvStart
        Long versamentoId = 1

        results.each {

            def versamento = [:]

            versamento.versamentoId = versamentoId++

            versamento.tipoVersamento = it['TIPO_VERSAMENTO'] as String
            versamento.dataPagamento = it['DATA_PAGAMENTO'] as JavaDate

            versamento.ruolo = it['RUOLO'] as Long
            versamento.rata = it['RATA'] as Short

            if (versamento.ruolo) {
                versamento.tipoVersamento += " - Lista n." + versamento.ruolo
            }

            versamento.importoVersato = (it['IMPORTO_VERSATO'] ?: 0) as BigDecimal
            versamento.imposta = it['IMPOSTA'] as BigDecimal
            versamento.addizionalePro = (it['ADDIZIONALE_PRO'] ?: 0) as BigDecimal
            versamento.sanzioni = (it['SANZIONI_1'] ?: 0) as BigDecimal
            versamento.interessi = (it['INTERESSI'] ?: 0) as BigDecimal
            versamento.sanzioniAddPro = (it['SANZIONI_ADD_PRO'] ?: 0) as BigDecimal
            versamento.interessiAddPro = (it['INTERESSI_ADD_PRO'] ?: 0) as BigDecimal
            versamento.speseSpedizione = (it['SPESE_SPEDIZIONE'] ?: 0) as BigDecimal
            versamento.speseMora = (it['SPESE_MORA'] ?: 0) as BigDecimal

            versamento.ravvLordo = it['RAVV_LORDO'] as BigDecimal
            versamento.ravvLordoRid = it['RAVV_LORDO_RID'] as BigDecimal
            versamento.ravvImpSanz = it['RAVV_IMP_SANZ'] as BigDecimal
            versamento.ravvImpSanzRid = it['RAVV_IMP_SANZ_RID'] as BigDecimal
            versamento.ravvInteressi = it['RAVV_INTERESSI'] as BigDecimal
            versamento.ravvSpese = it['RAVV_SPESE'] as BigDecimal

            versamento.totSanzioni = versamento.sanzioni + versamento.sanzioniAddPro
            versamento.totInteressi = versamento.interessi + versamento.interessiAddPro
            versamento.totAltro = versamento.speseSpedizione + versamento.speseMora

            scomponiVersamentoSuRavv(versamento)

            versamento.importo = versamento.importoVersato - versamento.totSanzioni - versamento.totInteressi - versamento.totAltro

            note = it['NOTE'] as String

            versamento.note = note
            versamento.idBack = it['IDBACK']

            if ((iuvStart = (note ?: '').indexOf('IUV: ')) >= 0) {
                IUV = note.substring(iuvStart + 5)
                IUV = IUV.tokenize(' ')[0]
            }
            versamento.IUV = IUV

            /// Scomposizione importi su ravvedimento

            versamenti << versamento
        }

        return versamenti
    }

    /// Verifica il lordo versato con il lordo del ravvedimento, se torna estrae le quote sanzioni, interessi e spese
    /// Altrimenti compila il campo ravvNote per beneficio dell'utente
    def scomponiVersamentoSuRavv(versamento) {

        boolean match

        DecimalFormat valutaForm = new DecimalFormat("€ #,###.00")

        String ravvNote = null

        /// C'è un lordo ma non ci sono ne sanzioni ne iteressi ne spese
        if ((versamento.ravvLordo) && (!versamento.totSanzioni) && (!versamento.totInteressi) && (!versamento.totAltro)) {

            match = false

            def versatoTotale = versamento.importoVersato

            /// Verifica se il versato lordo corrisponde al lordo del ravvedimento
            def ravvLordo = versamento.ravvLordo

            if (Math.abs(versatoTotale - ravvLordo) < 1.0) {

                versamento.totSanzioni = versamento.ravvImpSanz
                versamento.totInteressi = versamento.ravvInteressi
                versamento.totAltro = versamento.ravvSpese

                ravvNote = 'Corrispondenza di Versato Lordo con Importo Lordo :\n\n' +
                        'Scorporato Sanzioni, Interessi e Altro dai parziali del Ravvedimento'

                match = true
            } else {

                /// Verifica se il versato lordo corrisponde al lordo ridotto del ravvedimento
                ravvLordo = versamento.ravvLordoRid

                if (Math.abs(versatoTotale - ravvLordo) < 1.0) {

                    versamento.totSanzioni = versamento.ravvImpSanzRid
                    versamento.totInteressi = versamento.ravvInteressi
                    versamento.totAltro = versamento.ravvSpese

                    ravvNote = 'Corrispondenza di Versato Lordo con Importo Lordo Ridotto :\n\n' +
                            'Scorporato Sanzioni, Interessi e Altro dai parziali del Ravvedimento'

                    match = true
                }
            }

            if (!match) {

                /// No match, prepara dettaglio del ravvedimento

                ravvNote = 'Importo versato non corrispondente al totale del Ravvedimento.\n\n' +
                        "Impossibile scorporare Sanzioni, Interessi e Altro\n\n"

                ravvNote = ravvNote + ' - Lordo : ' + valutaForm.format(versamento.ravvLordo) + '\n'
                if (versamento.ravvLordo != versamento.ravvLordoRid) {
                    ravvNote = ravvNote + ' - Lordo Rid. : ' + valutaForm.format(versamento.ravvLordoRid) + '\n'
                }
                ravvNote = ravvNote + ' - Sanzioni : ' + valutaForm.format(versamento.ravvImpSanz) + '\n'
                if (versamento.ravvLordo != versamento.ravvLordoRid) {
                    ravvNote = ravvNote + ' - Sanzioni Rid. : ' + valutaForm.format(versamento.ravvImpSanzRid) + '\n'
                }
                ravvNote = ravvNote + ' - Interessi : ' + valutaForm.format(versamento.ravvInteressi) + '\n'
                ravvNote = ravvNote + ' - Altro : ' + valutaForm.format(versamento.ravvSpese)
            }
        }

        versamento.ravvNote = ravvNote
    }

    def getDettagliRuoliDaRavvedimento(def praticaId) {

        PraticaTributo pratica = PraticaTributo.get(praticaId)

        List<DebitoRavvedimento> debiti = DebitoRavvedimento.findAllByPratica(pratica)

        def dettagli = []
        def rata = [:]

        Long ruoloId = 1
        Long rataId = 1

        debiti.sort { it.ruolo }

        debiti.each { debito ->

            Ruolo ruolo = Ruolo.get(debito.ruolo)

            def dettaglio = [
                    ruoloId              : ruoloId++,
                    codFiscale           : pratica.contribuente.codFiscale,
                    ruolo                : debito.ruolo,
                    annoRuolo            : ruolo?.annoRuolo,
                    specieRuolo          : ruolo?.specieRuolo,
                    tipoRuolo            : ruolo?.tipoRuolo,
                    dataScadenzaRata1    : debito.scadenzaPrimaRata,
                    dataScadenzaRata2    : debito.scadenzaRata2,
                    dataScadenzaRata3    : debito.scadenzaRata3,
                    dataScadenzaRata4    : debito.scadenzaRata4,
                    capitalizzazioneRata1: ruolo?.scadenzaRataUnica ?: debito.scadenzaPrimaRata,
                    capitalizzazioneRata2: ruolo?.scadenzaRataUnica ?: debito.scadenzaRata2,
                    capitalizzazioneRata3: ruolo?.scadenzaRataUnica ?: debito.scadenzaRata3,
                    capitalizzazioneRata4: ruolo?.scadenzaRataUnica ?: debito.scadenzaRata4,
                    scadenzaRataUnica    : ruolo?.scadenzaRataUnica,
                    tipoEmissione        : ruolo?.tipoEmissione,
                    dataEmissione        : ruolo?.dataEmissione,
                    importoRuolo         : null,
                    impostaOgim          : null,
                    versatoOgim          : null,
                    addECAOgim           : null,
                    maggECAOgim          : null,
                    maggTARESOgim        : null,
                    addProOgim           : null,
                    ivaOgim              : null,
                    rate                 : [
                    ]
            ]

            if (debito.scadenzaPrimaRata != null) {
                rata = getDettagliRuoliDaRavvedimentoRata(1, debito.scadenzaPrimaRata, dettaglio.capitalizzazioneRata1,
                        debito.importoPrimaRata, debito.versatoPrimaRata, debito.maggiorazioneTaresPrimaRata)
                rata.rataId = rataId++
                dettaglio.rate << rata
            }
            if (debito.scadenzaRata2 != null) {
                rata = getDettagliRuoliDaRavvedimentoRata(2, debito.scadenzaRata2, dettaglio.capitalizzazioneRata2,
                        debito.importoRata2, debito.versatoRata2, debito.maggiorazioneTaresRata2)
                rata.rataId = rataId++
                dettaglio.rate << rata
            }
            if (debito.scadenzaRata3 != null) {
                rata = getDettagliRuoliDaRavvedimentoRata(3, debito.scadenzaRata3, dettaglio.capitalizzazioneRata3,
                        debito.importoRata3, debito.versatoRata3, debito.maggiorazioneTaresRata3)
                rata.rataId = rataId++
                dettaglio.rate << rata
            }
            if (debito.scadenzaRata4 != null) {
                rata = getDettagliRuoliDaRavvedimentoRata(4, debito.scadenzaRata4, dettaglio.capitalizzazioneRata4,
                        debito.importoRata4, debito.versatoRata4, debito.maggiorazioneTaresRata4)
                rata.rataId = rataId++
                dettaglio.rate << rata
            }

            dettaglio.maggTARES = dettaglio.rate.sum { it.maggTARES ?: 0 }

            dettaglio.descrizione = creaDescrizioneRuolo(dettaglio)

            dettagli << dettaglio
        }

        return dettagli
    }

    def getDettagliRuoliDaRavvedimentoRata(def rataNum, def dataScadenza, def dataCapitalizzazione, def importo, def versato,
                                           def maggTARES) {

        def rata = [
                rata                : rataNum,
                scadenzaRataDate    : dataScadenza,
                scadenzaRata        : dataScadenza.format("dd/MM/yyyy"),
                capitalizzazioneDate: dataCapitalizzazione,
                capitalizzazione    : dataCapitalizzazione.format("dd/MM/yyyy"),
                importo             : importo,
                imposta             : null,
                addECA              : null,
                maggECA             : null,
                maggTARES           : maggTARES,
                addPro              : null,
                iva                 : null,
                //
                versato             : versato,
                versatoDichiarato   : null,
                residuo             : (importo ?: 0) - (versato ?: 0),
                //
                superato            : (versato == null),
                scaduta             : (versato != null),
                //
                fissato             : 0
        ]

        return rata
    }

    def getCreditiDaRavvedimento(def praticaId) {

        PraticaTributo pratica = PraticaTributo.get(praticaId)

        List<CreditoRavvedimento> crediti = CreditoRavvedimento.findAllByPratica(pratica)

        def versamenti = []

        Long versamentoId = 1

        crediti.sort { it.sequenza }

        crediti.each { credito ->

            def versamento = [
                    versamentoId  : versamentoId++,
                    tipoVersamento: credito.descrizione,
                    rata          : credito.rata,
                    ruolo         : credito.ruolo,
                    dataPagamento : credito.dataPagamento,
                    importoVersato: credito.importoVersato,
                    importo       : (credito.importoVersato ?: 0) - (credito.sanzioni ?: 0) - (credito.interessi ?: 0) - (credito.altro ?: 0),
                    totSanzioni   : credito.sanzioni,
                    totInteressi  : credito.interessi,
                    totAltro      : credito.altro,
                    IUV           : credito.codIUV,
                    note          : "",
                    ravvNote      : credito.note
            ]

            versamenti << versamento
        }

        return versamenti
    }

    def creaDescrizioneRuolo(def ruolo) {

        String patternValuta = "€ #,##0.00"
        DecimalFormat valuta = new DecimalFormat(patternValuta)

        String descrizione

        descrizione = 'Lista n. ' + ruolo.ruolo
        descrizione += ' - ' + ((ruolo.tipoRuolo != 1) ? 'Supplettivo' : 'Principale')
        descrizione += ' ' + (tipoEmissione[ruolo.tipoEmissione] ?: '')
        descrizione += ' Anno ' + ruolo.annoRuolo
        descrizione += ' Emissione ' + ((ruolo.dataEmissione) ? ruolo.dataEmissione.format("dd/MM/yyyy") : '??')
        if (ruolo.scadenzaRataUnica) {
            descrizione += ' Scadenza Rata Unica ' + ruolo.scadenzaRataUnica.format("dd/MM/yyyy")
        }
        if (ruolo.maggTARES) {
            descrizione += ' Componenti perequative ' + valuta.format(ruolo.maggTARES)
        }

        return descrizione
    }

    /// Determina se la violazione richiede annullamento del dovuto
    def isDovutoDaAnnullareSuViolazione(def pratica) {

        return (pratica.tipoTributo.tipoTributo in ['CUNI']) && (pratica.tipoPratica in [TipoPratica.V.id, TipoPratica.A.id])
    }

    /// Determina i parametri per l'elimina dovuto dalla violazione
    def getDovutiDaAnnullareSUViolazione(def pratica) {

        def parametri = [
                codFiscale     : pratica.contribuente.codFiscale,
                anno           : pratica.anno,
                tipoTributo    : pratica.tipoTributo.tipoTributo,
                rata           : null,
                gruppoTributo  : null,
                tipoOccupazione: null,
        ]

        def gruppiTributo = integrazioneDePagService.getGruppiTributoPratica(pratica.id)

        if (gruppiTributo.size() > 0) {
            def gruppo = gruppiTributo[0]
            parametri.gruppoTributo = gruppo.gruppoTributo
            parametri.tipoOccupazione = gruppo.tipoOccupazione
        }

        if (parametri.tipoTributo in ['CUNI']) {
            switch (pratica.tipoPratica) {
                case TipoPratica.V.id:
                    switch (pratica.tipoEvento) {
                        default:
                            parametri.rata = null
                            break;
                        case TipoEventoDenuncia.R0:
                            parametri.rata = null
                            break
                        case TipoEventoDenuncia.R1:
                            parametri.rata = 1
                            break
                        case TipoEventoDenuncia.R2:
                            parametri.rata = 2
                            break
                        case TipoEventoDenuncia.R3:
                            parametri.rata = 3
                            break
                        case TipoEventoDenuncia.R4:
                            parametri.rata = 4
                            break
                    }
                    break;
                case TipoPratica.A.id:
                    parametri.rata = null
                    break;
            }
        }

        return parametri
    }

    /// Annulla il dovuto in relazione ad una pratica di violazione (Ravvedimento o Accertamento)
    def annullaDovutoSuViolazione(Long praticaId) {

        String result = ""

        PraticaTributo pratica = PraticaTributo.get(praticaId)
        if (pratica == null) {
            throw new Exception("Pratica ${praticaId} non trovato !")
        }

        if (isDovutoDaAnnullareSuViolazione(pratica)) {

            def parametri = getDovutiDaAnnullareSUViolazione(pratica)

            String message = integrazioneDePagService.eliminaDovutoImposta(parametri.codFiscale, parametri.anno, parametri.tipoTributo,
                    parametri.rata, parametri.gruppoTributo, parametri.tipoOccupazione)
            if (!message.isEmpty()) {
                result += message + "\n"
            }

            if (!result.isEmpty()) {
                result = "Attenzione :\n\n" +
                        "Impossibile annullare il dovuto superato dalla pratica ${praticaId}!\n\n" + result
            }
        }

        return result
    }

    /// Annulla le rate non scadute e non superate di un ravvedimento TARSU su Versamenti
    def annullaDovutoRuoliSuRavvedimento(Long praticaId) {

        String result = ""

        PraticaTributo pratica = PraticaTributo.get(praticaId)
        if (pratica == null) {
            throw new Exception("Pratica ${praticaId} non trovato !")
        }

        if (isRavvedimentoSuRuoli(pratica)) {

            String codFiscale = pratica.contribuente.codFiscale

            def ruoli = getRuoliDaAnnullareSuRavvedimento(praticaId)

            ruoli.each { ruolo ->

                String message = integrazioneDePagService.eliminaDovutoRuolo(codFiscale, ruolo.ruolo, ruolo.numRataMax)
                if (!message.isEmpty()) {
                    result += message + "\n"
                }

                /// println"Eliminato ${ruolo.numRataMax} rata/e del ruolo ${ruolo.ruolo}"
            }
            if (!result.isEmpty()) {
                result = "Attenzione :\n\n" +
                        "Impossibile annullare il dovuto dei ruoli collegati al ravvedimento ${praticaId}!\n\n" + result
            }
        }

        return result
    }

    /// Riporta numero ruolo e ultima rata superata da ravvedimento
    def getRuoliDaAnnullareSuRavvedimento(Long praticaId) {

        def filtri = [:]

        filtri << ['praticaId': praticaId]

        String sql = """
                select dbrv.ruolo,
                  case when dbrv.versato_rata_4 is not null then 4 else
                    case when dbrv.versato_rata_3 is not null then 3 else
                      case when dbrv.versato_rata_2 is not null then 2 else
                        1
                      end
                    end
                  end num_rata_max
                from
                    debiti_ravvedimento dbrv,
                    ruoli ruol
                where
                    dbrv.ruolo = ruol.ruolo 
                and dbrv.versato_prima_rata is not null
                and dbrv.pratica = :praticaId
                and ruol.flag_depag = 'S'
        """

        def results = eseguiQuery(sql, filtri, null, true)

        def ruoli = []

        results.each {

            def ruolo = [:]

            ruolo.ruolo = it['RUOLO'] as Long
            ruolo.numRataMax = it['NUM_RATA_MAX'] as Long

            ruoli << ruolo
        }

        return ruoli
    }

    // Esegue calcolo Accertamento
    def calcolaAccertamentoManuale(PraticaTributoDTO pratica, def impostazioni, List oggettiAccManuale) {

        String message = ''
        Long result = 0

        Short anno = pratica.anno
        Boolean flagNormalizzato = (impostazioni.calcoloNormalizzato != null) ? impostazioni.calcoloNormalizzato : true

        try {
            if (!(pratica.tipoTributo.tipoTributo in ['ICI', 'TARSU'])) {
                throw new Exception("ORA-20999: Tributo non supportato\n")
            }

            def catalogoModifiche = []

            def parametri = [
                    flagNormalizzato: flagNormalizzato
            ]

            oggettiAccManuale.each {
                calcolaAccertamentoManualeOgCo(anno, parametri, pratica, it, catalogoModifiche)
            }

            ///
            /// Per il calcolo totale usa un catalogo delle modifiche e le applica
            /// tutte in una volta, così evita rrori strani di transazioni
            ///
            List<OggettoImposta> oggImmRawOld
            OggettoContribuente ogCoRaw
            OggettoContribuenteDTO ogCo
            OggettoImposta ogImmRaw
            OggettoImpostaDTO ogImm

            eliminaTutteLeSanzioni(pratica.id)
            pratica.sanzioniPratica = []

            oggettiAccManuale.each {

                ogCo = it
                ogCoRaw = it.toDomain()

                oggImmRawOld = OggettoImposta.findAllByOggettoContribuente(ogCoRaw)
                oggImmRawOld.each {
                    it.delete(flush: true, failOnError: true)
                }
                oggImmRawOld.clear()

                if (ogCo.oggettiImposta) {
                    ogCo.oggettiImposta.clear()
                }
            }

            catalogoModifiche.each { oggImmGenerato ->

                ogImmRaw = oggImmGenerato.ogImmRaw
                ogCo = oggImmGenerato.ogCo

                ogImmRaw.save(flush: true, failOnError: true)
                ogImm = ogImmRaw.toDTO()

                ogCo.addToOggettiImposta(ogImm)
            }
        }
        catch (Exception e) {
            if (e?.message?.startsWith("ORA-20999")) {
                message = e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                result = 2
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message = e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                result = 2
            } else {
                throw e
            }
        }

        return [result: result, message: message]
    }

    // Esegue calcolo Accertamento
    def calcolaAccertamentoManualeOgCo(Short anno, Map parametri, PraticaTributoDTO pratica, OggettoContribuenteDTO ogCo, def catalogoModifiche = null) {

        String message = ''
        Long result = 0

        String tipoTributo

        try {
            tipoTributo = pratica.tipoTributo.tipoTributo

            if (!(tipoTributo in ['ICI', 'TARSU'])) {
                throw new Exception("ORA-20999: Tributo non supportato\n")
            }

            List<OggettoImposta> oggImmRaw
            List<OggettoImposta> oggImmRawOld
            List<OggettoImpostaDTO> oggImm
            OggettoImposta ogImmRaw
            OggettoImpostaDTO ogImm
            OggettoContribuente ogCoRaw

            if (tipoTributo == 'ICI') {

                oggImmRaw = []
                calcolaAccertamentoIci(anno, parametri, pratica, ogCo, oggImmRaw)
            }

            if (tipoTributo == 'TARSU') {

                def flagNormalizzato = parametri.flagNormalizzato
                if (flagNormalizzato == null) {
                    flagNormalizzato = pratica.tipoCalcolo == 'N'
                }

                oggImmRaw = []
                calcolaAccertamentoTarsu(anno, flagNormalizzato, pratica, ogCo, oggImmRaw)
            }

            if (catalogoModifiche != null) {

                oggImmRaw.each {
                    def oggImmGenerato = [
                            ogImmRaw: it,
                            ogCo    : ogCo
                    ]
                    catalogoModifiche << oggImmGenerato
                }
            } else {
                ogCoRaw = ogCo.toDomain()

                oggImmRawOld = OggettoImposta.findAllByOggettoContribuente(ogCoRaw)
                oggImmRawOld.each {
                    it.delete(flush: true, failOnError: true)
                }
                oggImmRawOld.clear()

                if (ogCo.oggettiImposta) {
                    ogCo.oggettiImposta.clear()
                }

                oggImmRaw.each {

                    ogImmRaw = it

                    ogImmRaw.save(flush: true, failOnError: true)
                    ogImm = ogImmRaw.toDTO()

                    ogCo.addToOggettiImposta(ogImm)
                }
            }
        }
        catch (Exception e) {
            if (e?.message?.startsWith("ORA-20999")) {
                message = e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                result = 2
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message = e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                result = 2
            } else {
                throw e
            }
        }

        return [result: result, message: message]
    }

    // Esegue calcolo Sanzioni Accertamento
    def calcolaSanzioniAccertamentoManuale(PraticaTributoDTO pratica, def impostazioni, List oggettiAccManuale) {

        String message = ''
        Long result = 0

        String tipoTributo
        Short anno
        Boolean nuovoSanzionamento

        try {
            tipoTributo = pratica.tipoTributo.tipoTributo

            if (!(tipoTributo in ['ICI', 'TARSU'])) {
                throw new Exception("ORA-20999: Tributo non supportato\n")
            }

            eliminaTutteLeSanzioni(pratica.id)
            pratica.sanzioniPratica = []

            anno = pratica.anno

            // Aggiunge Sanzioni per Spese di Notifica al primo Oggetto Sanzionato
            nuovoSanzionamento = true

            def dichiarati = getDichiaratiOggPr(oggettiAccManuale, anno)
            def liquidati = []

            if (tipoTributo in ['ICI']) {
                liquidati = getLiquidatiOggPr(oggettiAccManuale, anno)
            }

            int numeroOggettiResidui = oggettiAccManuale.size()

            oggettiAccManuale.each {

                numeroOggettiResidui--

                OggettoContribuenteDTO ogCo = it

                OggettoPraticaDTO ogPr = ogCo.oggettoPratica
                ContribuenteDTO cont = ogCo.contribuente

                def oggettoRif = getOggettoPratricaRif(ogCo)

                if (tipoTributo == 'ICI') {

                    impostazioni.numeroOggettiResidui = numeroOggettiResidui

                    def dichiarato = dichiarati.find { it.oggPrAccId == oggettoRif.id }
                    def liquidato = liquidati.find { it.oggPrAccId == oggettoRif.id }
                    def accertato = getImpostaOggPrIci(ogPr.id, anno, cont.codFiscale, false)
                    def parametri = determinaParametriSanzioniAccertamentoIci(dichiarato, liquidato, accertato, pratica, impostazioni, ogCo)

                    if (Math.abs(parametri.deltaImposta) > 0.01) {

                        calcolaSanzioniAccertamentoICI(anno, parametri, true, pratica, ogCo)
                        aggiornaOggettoImpostaIci(accertato, parametri)
                    }
                }

                if (tipoTributo == 'TARSU') {

                    def dichiarato = dichiarati.find { it.oggPrAccId == oggettoRif.id }
                    def accertato = getImpostaOggPrTarsu(ogPr.id, anno, cont.codFiscale, false)
                    def parametri = determinaParametriSanzioniAccertamentoTarsu(dichiarato, accertato, pratica, impostazioni)

                    if ((Math.abs(parametri.deltaImposta) + Math.abs(parametri.deltaMaggTARES)) > 0.01) {

                        calcolaSanzioniAccertamentoTARSU(anno, parametri, nuovoSanzionamento, pratica, ogCo)
                        aggiornaOggettoImpostaTARSU(accertato, parametri)
                    }
                }

                if (nuovoSanzionamento) {
                    if (hasSanzioni(pratica.id)) {
                        // Spese di notifica solo per il primo Oggetto Sanzionato
                        nuovoSanzionamento = false
                    }
                }
            }
            mergeSanzioniPratica(pratica, impostazioni.interessiDal, impostazioni.interessiAl)
        }
        catch (Exception e) {
            if (e?.message?.startsWith("ORA-20999")) {
                message = e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                result = 2
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message = e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                result = 2
            } else {
                throw e
            }
        }

        return [result: result, message: message]
    }

    // Calcola accertamento ICI singolo oggetto
    def calcolaAccertamentoIci(Short anno, def parametri, PraticaTributoDTO pratica, OggettoContribuenteDTO ogCo, List<OggettoImposta> oggIm) {

        List<OggettoImposta> oggImAcconto = []
        List<OggettoImposta> oggImSaldo = []

        String messaggio

        Double detrazioneOgCo = ogCo.detrazione ?: 0

        TipoAliquota tipoAliquota = TipoAliquota.findByTipoAliquotaAndTipoTributo(parametri.tipoAliquota, pratica.tipoTributo.toDomain())
        if (tipoAliquota == null) {
            throw new Exception("Tipo aliquota ${parametri.tipoAliquota} non trovato !")
        }
        Aliquota aliquota = Aliquota.findByTipoAliquotaAndAnno(tipoAliquota, anno)
        if (aliquota == null) {
            throw new Exception("Aliquota ${parametri.tipoAliquota} per anno ${anno} non trovata !")
        }

        Double percSaldo = aliquota.percSaldo

        def parametriSaldo = parametri.clone()
        parametriSaldo.periodoCalcolo = 'S'
        parametriSaldo.detrazione = detrazioneOgCo

        messaggio = calcolaAccertamentoIciPeriodo(anno, parametriSaldo, pratica, ogCo, oggImSaldo)

        if (messaggio == "OK") {

            Double dMP = (ogCo.mesiPossesso ?: 12) as Double
            Double dMP1S = (ogCo.mesiPossesso1sem ?: 0) as Double
            Double detrazioneAcc

            if (dMP > 0) {
                detrazioneAcc = round((detrazioneOgCo / dMP * dMP1S), 2)
            } else {
                detrazioneAcc = 0.0
            }

            def parametriAcconto = parametri.clone()
            parametriAcconto.periodoCalcolo = 'A'
            parametriAcconto.tipoAliquotaAcc = parametri.tipoAliquota
            parametriAcconto.aliquotaAcc = parametri.aliquota
            parametriAcconto.detrazioneAcc = detrazioneOgCo        // detrazioneAcc

            messaggio = calcolaAccertamentoIciPeriodo(anno, parametriAcconto, pratica, ogCo, oggImAcconto)

            if (messaggio == "OK") {

                OggettoImposta ogImAcconto = oggImAcconto[0]
                OggettoImposta ogImSaldo = oggImSaldo[0]

                Double imposta
                Double impostaAcconto

                if (dMP > 0) {
                    imposta = ogImSaldo.imposta
                    impostaAcconto = round(((ogImAcconto.imposta / dMP) * dMP1S), 2)
                    if (impostaAcconto > imposta) {
                        impostaAcconto = imposta
                    }
                } else {
                    imposta = 0.0
                    impostaAcconto = 0.0
                }

                if (percSaldo != null) {
                    Double detrazione = ogImSaldo.detrazione

                    Double impostaSaldo = round(imposta * percSaldo * 0.01, 2)
                    Double detrazioneSaldo = round(detrazione * percSaldo * 0.01, 2)
                    impostaAcconto = imposta - impostaSaldo
                    detrazioneAcc = detrazione - detrazioneSaldo

                    DecimalFormat fmtPerc = new DecimalFormat("#,##0.00")
                    ogImSaldo.note = "Perc.saldo " + fmtPerc.format(percSaldo)
                }

                ogImSaldo.imposta = imposta
                ogImSaldo.impostaAcconto = impostaAcconto

                ogImSaldo.aliquotaAcconto = ogImAcconto.aliquota
                ogImSaldo.detrazioneAcconto = detrazioneAcc        // ogImAcconto.detrazione

                ogImSaldo.tipoAliquotaPrec = ogImAcconto.tipoAliquota
                ogImSaldo.aliquotaPrec = ogImAcconto.aliquota

                oggIm << ogImSaldo
            }
        }

        return messaggio
    }

    // Calcola accertamento ICI singolo oggetto - Acconto o Saldo
    def calcolaAccertamentoIciPeriodo(Short anno, def parametri, PraticaTributoDTO pratica, OggettoContribuenteDTO ogCo, List<OggettoImposta> oggIm) {

        def messaggio = ""

        try {
            String pUtente = springSecurityService.currentUser.id

            OggettoPraticaDTO ogPr = ogCo.oggettoPratica

            String flagValoreRivalutato = (ogPr.flagValoreRivalutato) ? 'S' : null
            String flagRiduzione = (ogCo.flagRiduzione) ? 'S' : null

            def tipoAliquota
            Double aliquota
            Double detrazione

            if (parametri.periodoCalcolo == 'A') {
                tipoAliquota = parametri.tipoAliquotaAcc
                aliquota = parametri.aliquotaAcc
                detrazione = parametri.detrazioneAcc
            } else {
                tipoAliquota = parametri.tipoAliquota
                aliquota = parametri.aliquota
                detrazione = parametri.detrazione
            }

            Double versato = parametri.versato

            def mesiPossesso = ogCo.mesiPossesso
            // Se non si valorizza in questo modo la variabile si ha un errore in fase di esecuzioen della procedure.
            // Vedere: https://redmine.finmatica.it/issues/64021#note-19
            def mesiRiduzione = ogCo.mesiRiduzione ?: (ogCo.flagRiduzione ? ogCo.mesiPossesso : 0)

            /// Come per il calcolo normale l'immobile storico lo gestisce applicando i mesi di riduzione
            if ((ogPr.anno >= 2012) && (ogPr.immStorico)) {
                mesiRiduzione = ogCo.mesiPossesso
            }

            if ((tipoAliquota == null) || (aliquota == null)) {
                throw new Exception("Aliquota Oggetto ${ogPr.oggetto.id} non impostata !")
            }

            Sql sql = new Sql(dataSource)

            sql.call('{ call CALCOLO_ACCERTAMENTO_ICI(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}',
                    [
                            //	a_anno                    IN     number
                            anno,
                            //	a_tipo_oggetto            IN     number
                            ogPr.oggetto.tipoOggetto.tipoOggetto,
                            //	a_valore                  IN     number
                            ogPr.valore,
                            //	a_flag_valore_rivalutato  IN     varchar2
                            flagValoreRivalutato,
                            //	a_tipo_aliquota           IN OUT number
                            tipoAliquota,
                            //	a_aliquota                IN     number
                            aliquota,
                            //	a_perc_possesso           IN     number
                            ogCo.percPossesso,
                            //	a_mesi_possesso           IN OUT number
                            mesiPossesso,
                            //	a_mesi_esclusione         IN     number
                            ogCo.mesiEsclusione,
                            //	a_mesi_riduzione          IN OUT number
                            mesiRiduzione,
                            //	a_flag_riduzione          IN     varchar2
                            flagRiduzione,
                            //	a_detrazione              IN     number
                            detrazione,
                            //	a_anno_dic                IN     number
                            pratica.anno,
                            //	a_categoria_catasto       in     varchar2
                            ogPr.categoriaCatasto?.categoriaCatasto,
                            //	a_imposta				  IN OUT   number
                            Sql.DECIMAL
                    ],
                    { a_imposta ->

                        OggettoImposta ogIm = new OggettoImposta()

                        TipoTributo tipoTributo = TipoTributo.get(pratica.tipoTributo.tipoTributo)
                        List<TipoAliquota> tipiAliquota = TipoAliquota.findAllByTipoTributo(tipoTributo)

                        ogIm.tipoTributo = tipoTributo
                        ogIm.anno = anno
                        ogIm.oggettoContribuente = ogCo.toDomain()

                        ogIm.imposta = a_imposta

                        ogIm.impostaAcconto = 0.0

                        ogIm.importoVersato = versato

                        ogIm.detrazione = detrazione

                        ogIm.mesiPossesso = (Short) mesiPossesso

                        Short tipoAliquotaShort = (Short) tipoAliquota

                        TipoAliquota tipoAliquotaRaw = tipiAliquota.find { it.tipoAliquota == tipoAliquotaShort }
                        Aliquota aliquotaRaw = tipoAliquotaRaw.aliquote.find { it.anno == anno }

                        ogIm.tipoAliquota = tipoAliquotaRaw
                        ogIm.aliquota = aliquota

                        ogIm.aliquotaErariale = aliquotaRaw?.aliquotaErariale
                        ogIm.aliquotaStd = aliquotaRaw?.aliquotaStd

                        ogIm.utente = pUtente

                        oggIm << ogIm
                    }
            )

            messaggio = "OK"
        }
        catch (Exception e) {
            if (e?.message?.startsWith("ORA-20999")) {
                throw new Application20999Error(e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n')))
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                throw new Application20999Error(e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n')))
            } else {
                throw e
            }
        }

        return messaggio
    }

    // Calcola accertamento TARSU singolo oggetto
    def calcolaAccertamentoTarsu(Short anno, Boolean calcoloNormalizzato, PraticaTributoDTO pratica, OggettoContribuenteDTO ogCo, List<OggettoImposta> oggIm) {

        def messaggio = ""

        try {
            String pUtente = springSecurityService.currentUser.id

            OggettoPraticaDTO ogPr = ogCo.oggettoPratica
            ContribuenteDTO cont = ogCo.contribuente

            String flagNormalizzato = (calcoloNormalizzato) ? 'S' : null
            String flagAbPrincipale = (ogCo.flagAbPrincipale) ? 'S' : null

            Sql sql = new Sql(dataSource)

            sql.call('{ call CALCOLO_ACCERTAMENTO_TARSU(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}',
                    [
                            // a_anno                IN       number
                            anno,
                            // a_consistenza         IN       number
                            ogPr.consistenza,
                            // a_data_decorrenza     IN       date
                            ogCo.dataDecorrenza ? new java.sql.Date(ogCo.dataDecorrenza.getTime()) : null,
                            // a_data_cessazione     IN       date
                            ogCo.dataCessazione ? new java.sql.Date(ogCo.dataCessazione.getTime()) : null,
                            // a_percentuale         IN       number
                            ogCo.percPossesso,
                            // a_tributo             IN       number
                            ogPr.codiceTributo?.id,
                            // a_categoria           IN       number
                            ogPr.categoria?.categoria,
                            // a_tipo_tariffa        IN       number
                            ogPr.tariffa?.tipoTariffa,
                            // a_oggetto_pratica     IN       number
                            ogPr.id,
                            // a_oggetto_pratica_rif IN       number
                            ogPr.oggettoPraticaRif?.id,
                            // a_cod_fiscale         IN       varchar2
                            cont.codFiscale,
                            // a_ni                  IN       number
                            cont.soggetto.id,
                            // a_flag_normalizzato   IN       varchar2
                            flagNormalizzato,
                            // a_flag_ab_principale  IN       varchar2
                            flagAbPrincipale,
                            // a_tipo_occupazione    IN       varchar2
                            ogPr.tipoOccupazione?.tipoOccupazione,
                            // a_numero_familiari    IN       varchar2
                            ogPr.numeroFamiliari,
                            //	a_imposta             IN OUT   number
                            Sql.DECIMAL,
                            //	a_imposta_lorda       IN OUT   number
                            Sql.DECIMAL,
                            //	a_flag_lordo          IN OUT   varchar2
                            Sql.VARCHAR,
                            //	a_magg_tares          IN OUT   number
                            Sql.DECIMAL,
                            //	a_dettaglio_ogim      IN OUT   varchar2
                            Sql.VARCHAR,
                            //	a_add_eca             IN OUT   number
                            Sql.DECIMAL,
                            //	a_magg_eca            IN OUT   number
                            Sql.DECIMAL,
                            //	a_add_prov            IN OUT   number
                            Sql.DECIMAL,
                            //	a_iva                 IN OUT   number
                            Sql.DECIMAL,
                            //	a_stringa_familiari   IN OUT   varchar2
                            Sql.VARCHAR,
                            //	a_importo_pf          IN OUT   number
                            Sql.DECIMAL,
                            //	a_importo_pv          IN OUT   number
                            Sql.DECIMAL,
                            //	a_tipo_tariffa_base   IN OUT   number
                            Sql.DECIMAL,
                            //	a_importo_base        IN OUT   number
                            Sql.DECIMAL,
                            //	a_add_eca_base        IN OUT   number
                            Sql.DECIMAL,
                            //	a_magg_eca_base       IN OUT   number
                            Sql.DECIMAL,
                            //	a_add_prov_base       IN OUT   number
                            Sql.DECIMAL,
                            //	a_iva_base            IN OUT   number
                            Sql.DECIMAL,
                            //	a_importo_pf_base     IN OUT   number
                            Sql.DECIMAL,
                            //	a_importo_pv_base     IN OUT   number
                            Sql.DECIMAL,
                            //	a_perc_rid_pf         IN OUT   number
                            Sql.DECIMAL,
                            //	a_perc_rid_pv         IN OUT   number
                            Sql.DECIMAL,
                            //	a_importo_pf_rid      IN OUT   number
                            Sql.DECIMAL,
                            //	a_importo_pv_rid      IN OUT   number
                            Sql.DECIMAL,
                            //	a_dettaglio_ogim_base IN OUT   varchar2
                            Sql.VARCHAR,
                            // a_imposta_periodo     IN OUT   number
                            Sql.DECIMAL
                    ],
                    { a_imposta, a_imposta_lorda, a_flag_lordo, a_magg_tares, a_dettaglio_ogim, a_add_eca,
                      a_magg_eca, a_add_prov, a_iva, a_stringa_familiari, a_importo_pf, a_importo_pv,
                      a_tipo_tariffa_base, a_importo_base, a_add_eca_base, a_magg_eca_base, a_add_prov_base,
                      a_iva_base, a_importo_pf_base, a_importo_pv_base, a_perc_rid_pf, a_perc_rid_pv,
                      a_importo_pf_rid, a_importo_pv_rid, a_dettaglio_ogim_base, a_imposta_periodo ->

                        if (Math.abs(a_imposta ?: 0) > 0.0) {

                            OggettoImposta ogIm = new OggettoImposta()

                            ogIm.tipoTributo = TipoTributo.get(pratica.tipoTributo.tipoTributo)
                            ogIm.anno = anno
                            ogIm.oggettoContribuente = ogCo.toDomain()

                            ogIm.imposta = a_imposta
                            ogIm.impostaPeriodo = a_imposta_periodo
                            ogIm.maggiorazioneTares = a_magg_tares
                            ogIm.dettaglioOgim = a_dettaglio_ogim
                            ogIm.addizionaleEca = a_add_eca
                            ogIm.maggiorazioneEca = a_magg_eca
                            ogIm.addizionalePro = a_add_prov
                            ogIm.iva = a_iva
                            ogIm.importoPf = a_importo_pf
                            ogIm.importoPv = a_importo_pv

                            ogIm.tipoTariffaBase = a_tipo_tariffa_base
                            ogIm.impostaBase = a_importo_base
                            ogIm.addizionaleEcaBase = a_add_eca_base
                            ogIm.maggiorazioneEcaBase = a_magg_eca_base
                            ogIm.addizionaleProBase = a_add_prov_base
                            ogIm.ivaBase = a_iva_base
                            ogIm.importoPfBase = a_importo_pf_base
                            ogIm.importoPvBase = a_importo_pv_base

                            ogIm.percRiduzionePf = a_perc_rid_pf
                            ogIm.percRiduzionePv = a_perc_rid_pv
                            ogIm.importoRiduzionePf = a_importo_pf_rid
                            ogIm.importoRiduzionePv = a_importo_pv_rid
                            ogIm.dettaglioOgimBase = a_dettaglio_ogim_base

                            ogIm.familiariOgim = []

                            if (a_stringa_familiari) {
                                preparaFamiliariOgim(ogIm, a_stringa_familiari, a_dettaglio_ogim, a_dettaglio_ogim_base)
                            }

                            ogIm.utente = pUtente

                            oggIm << ogIm
                        }
                    }
            )

            messaggio = "OK"
        }
        catch (Exception e) {
            commonService.serviceException(e)
        }

        return messaggio
    }

    String verificaAccertamentoReplicabile(Long praticaId) {

        String message = ''

        PraticaTributo pratica = PraticaTributo.get(praticaId)
        String tipoTributo = pratica.tipoTributo.tipoTributo
        Short anno = pratica.anno

        if (pratica.flagDenuncia) {
            message += 'Flag Denuncia impostato\n'
        }

        switch (tipoTributo) {
            default:
                message += 'Operazione non consentita per tributo ' + tipoTributo + '\n'
                break;
            case 'ICI':
                if (verificaAccertamentoReplicabileAnomalie(praticaId, tipoTributo) > 0) {
                    message += 'Almeno un oggetto presenta un Flag al 31/12 (PERA) impostato!\n'
                }
                break;
            case 'TARSU':
                if (verificaAccertamentoReplicabileAnomalie(praticaId, tipoTributo) < 1) {
                    message += 'Nessuno degli oggetti risulta attivo al 31/12/' + (anno as String) + '!\n'
                }
                break;
        }

        if (!message.isEmpty()) {
            message = message + '\nImpossibile procedere!'
        }

        return message;
    }

    def verificaAccertamentoReplicabileAnomalie(Long praticaId, String tipoTributo) {

        String sql

        def filtri = ['praticaId': praticaId]

        if (tipoTributo == 'ICI') {

            sql = """
                    select count(ogpr.oggetto_pratica) as conteggio
                      from pratiche_tributo prtr,
                           oggetti_pratica ogpr,
                           oggetti_contribuente ogco
                     where prtr.pratica = :praticaId 
                       and ogpr.pratica = prtr.pratica
                       and ogpr.oggetto_pratica = ogco.oggetto_pratica
                       and ogco.cod_fiscale = prtr.cod_fiscale
                       and (   (ogco.flag_possesso is not null)
                            or (ogco.flag_esclusione is not null)
                            or (ogco.flag_al_ridotta is not null)
                            or (ogco.flag_ab_principale is not null)
                       )
            """
        } else if (tipoTributo == 'TARSU') {
            sql = """
                    select count(ogpr.oggetto_pratica) as conteggio
                      from pratiche_tributo prtr,
                           oggetti_pratica ogpr,
                           oggetti_contribuente ogco
                     where prtr.pratica = :praticaId  
                       and ogpr.pratica = prtr.pratica
                       and ogpr.oggetto_pratica = ogco.oggetto_pratica
                       and ogco.cod_fiscale = prtr.cod_fiscale
                       and nvl(ogco.data_cessazione,to_date(prtr.anno||'1231','YYYYMMdd')) >= 
                                                            to_date(prtr.anno||'1231','YYYYMMdd')
            """
        } else {
            sql = "SELECT 1 as conteggio FROM DUAL"
        }

        def results = eseguiQuery(sql, filtri, null, true)

        Long conteggio = 0

        results.each {

            conteggio = it['CONTEGGIO'] as Long
        }

        return conteggio
    }

    def replicaAccertamento(Long praticaId, Short praticaAnno, def impostazioni) {

        def elencoPratiche = []
        String listaPratiche = '';

        String flagRivalutato = (impostazioni.valoreRivalutato) ? 'S' : null

        try {
            Sql sql = new Sql(dataSource)
            sql.call('{call replica_accertamento(?, ?, ?, ?, ?, ?, ?, ?, ?)}',
                    [
                            praticaId,
                            impostazioni.annoDa as Integer,
                            impostazioni.annoA as Integer,
                            new java.sql.Date(impostazioni.dataEmissione.getTime()),
                            impostazioni.dateInizio,
                            impostazioni.dateFine,
                            flagRivalutato,
                            springSecurityService.currentUser.id,
                            Sql.VARCHAR
                    ],
                    { res ->
                        listaPratiche = res
                    }
            )
        }
        catch (Exception e) {
            commonService.serviceException(e)
        }

        def length = (listaPratiche ?: '').size()
        if (length != 0) {

            def praticheNum = length / 10

            String subStr
            def index
            def ptr

            Long praticaReplica
            Short annoReplica = impostazioni.annoDa as Short

            for (index = 0; index < praticheNum; index++) {

                ptr = index * 10
                subStr = listaPratiche.substring(ptr, ptr + 10)
                praticaReplica = Long.valueOf(subStr)

                elencoPratiche << [anno: annoReplica, pratica: praticaReplica]

                annoReplica++
            }
        }

        return elencoPratiche
    }

    def preparaFamiliariOgim(OggettoImposta ogIm, String strFamiliari, String strDettaglio, String strDettBase) {

        SimpleDateFormat sdf = new SimpleDateFormat("ddMMyyyy")

        FamiliareOgim famOgIm

        int sizeFam = strFamiliari.length()
        int sizeDett = strDettaglio.length()
        int sizeDettB = strDettBase.length()

        int blocchiFam = sizeFam / 20
        int blocchiDett = sizeDett / 150
        int blocchiDettB = sizeDettB / 170

        int remFam = sizeFam % 20
        int remDett = sizeDett % 150
        int remDettB = sizeDettB % 170

        if ((remFam != 0) || (remDett != 0) || (remDettB != 0) ||
                (blocchiFam != blocchiDett) || (blocchiFam != blocchiDettB)) {
            log.info "preparaFamiliariOgim - Incoerenza lunghezza strighe : ${sizeFam} / ${sizeDett} / ${sizeDettB}"
            return
        }

        String desFam
        String desDett
        String desDettBase
        String temp

        Short famNum
        java.sql.Date famDal
        java.sql.Date famAl

        int blocco
        int ptr
        int bloccoSize

        for (blocco = 0; blocco < blocchiFam; blocco++) {

            bloccoSize = 20
            ptr = blocco * bloccoSize
            desFam = strFamiliari.substring(ptr, ptr + bloccoSize)
            bloccoSize = 150
            ptr = blocco * bloccoSize
            desDett = '*' + strDettaglio.substring(ptr + 1, ptr + bloccoSize)
            bloccoSize = 170
            ptr = blocco * bloccoSize
            desDettBase = '*' + strDettBase.substring(ptr + 1, ptr + bloccoSize)

            temp = desFam.substring(0, 4)
            famNum = temp as Short
            temp = desFam.substring(4, 12)
            famDal = new java.sql.Date(sdf.parse(temp).getTime())
            temp = desFam.substring(12, 20)
            famAl = new java.sql.Date(sdf.parse(temp).getTime())

            famOgIm = new FamiliareOgim()

            famOgIm.oggettoImposta = ogIm
            famOgIm.numeroFamiliari = famNum
            famOgIm.dal = famDal
            famOgIm.al = famAl
            famOgIm.dettaglioFaog = desDett
            famOgIm.dettaglioFaogBase = desDettBase
            famOgIm.note = ""

            ogIm.familiariOgim.add(famOgIm)
        }
    }

    /// Verifica situazione familiari per annoe tariffa tarsu
    def verificaFamiliariAccertamentoTarsu(def pratica, OggettoContribuenteDTO ogCo) {

        long result = 0
        String message = ""

        Boolean flagNormalizzato = (pratica.tipoCalcolo == 'N')

        if (flagNormalizzato) {

            OggettoPraticaDTO ogPr = ogCo.oggettoPratica
            CategoriaDTO categoria = ogPr.categoria

            Boolean esisteCoSu
            Short anno = pratica.anno as Short

            if (categoria.flagDomestica == 'S') {

                if (ogCo.flagAbPrincipale != false) {
                    esisteCoSu = false
                } else {
                    int numCoSu = ComponentiSuperficie.findAllByAnno(anno).size()
                    esisteCoSu = (numCoSu > 0)
                }

                if (!esisteCoSu) {

                    Soggetto sogg = ogCo.contribuente.soggetto.getDomainObject()

                    int numFaSo = FamiliareSoggetto.findAllBySoggettoAndAnno(sogg, anno).size()
                    if (numFaSo < 1) {
                        if (result < 1) result = 1;
                        if (!message.isEmpty()) message += "\n"
                        message += "Inserire il Numero Familiari per l'anno ${anno}"
                    }
                }
            }
        }

        return [result: result, message: message]
    }

    // Determina i parametri da passare alla procedura di calcolo sanzioni dell'accertamento
    def determinaParametriSanzioniAccertamentoIci(def dichiarato, def liquidato, def accertato, PraticaTributoDTO pratica,
                                                  def impostazioni, OggettoContribuenteDTO ogCo) {

        def baseImposta = liquidato ?: dichiarato

        Short mesiPossesso = ogCo.mesiPossesso
        Short mesiPossesso1sem = ogCo.mesiPossesso1sem

        Double imposta = accertato.imposta ?: 0.0
        Double impostaAcconto = accertato.impostaAcconto ?: 0.0

        Double impostaDichiarata = null
        Double impostaAccontoDichiarata = null

        if (baseImposta) {
            if (baseImposta.residuoRiferimenti > 1) {
                Double porzionePeriodo = (Double) mesiPossesso / 12.0
                Double porzionePeriodoAcconto = (Double) mesiPossesso1sem / 6.0
                impostaDichiarata = round(baseImposta.imposta * porzionePeriodo, 2)
                impostaAccontoDichiarata = round(baseImposta.impostaAcconto * porzionePeriodoAcconto, 2)
                baseImposta.residuoRiferimenti--
            } else {
                impostaDichiarata = baseImposta.residuoImposta
                impostaAccontoDichiarata = baseImposta.residuoImpostaAcconto
            }
            baseImposta.residuoImposta -= impostaDichiarata
            baseImposta.residuoImpostaAcconto -= impostaAccontoDichiarata
        }

        Double importoVersato = accertato.versato

        def parametri = [
                dataAccertamento        : pratica.data,
                //
                mesiPossesso            : mesiPossesso,
                mesiPossessoDichiarati  : null,
                mesiPossesso1S          : mesiPossesso1sem,
                flagPossessoDichiarato  : null,
                //
                importoVersato          : importoVersato,
                //
                imposta                 : imposta,
                impostaDichiarata       : impostaDichiarata,
                deltaImposta            : imposta - (impostaDichiarata ?: 0),
                //
                impostaAcconto          : impostaAcconto,
                impostaAccontoDichiarata: impostaAccontoDichiarata,
                deltaImpostaAcconto     : impostaAcconto - (impostaAccontoDichiarata ?: 0),
        ]

        return parametri
    }

    // Determina i parametri da passare alla procedura di calcolo sanzioni dell'accertamento - TARSU
    def determinaParametriSanzioniAccertamentoTarsu(def dichiarato, def accertato, PraticaTributoDTO accertamento, def impostazioni) {

        Short annoDenuncia = null
        def dataDenuncia = null

        Double imposta = accertato.imposta ?: 0.0
        Double maggTARES = accertato.maggTARES ?: 0.0
        Double porzionePeriodo = accertato.periodo

        Short annoDichiarazione = 0
        Double impostaDichiarata = null
        Double maggTARESDichiarata = null

        if (dichiarato) {
            annoDichiarazione = dichiarato.annoPratica ?: 0

            if (dichiarato.residuoRiferimenti > 1) {
                impostaDichiarata = round(dichiarato.imposta * porzionePeriodo, 2)
                maggTARESDichiarata = round(dichiarato.maggTARES * porzionePeriodo, 2)
                dichiarato.residuoRiferimenti--
            } else {
                impostaDichiarata = dichiarato.residuoImposta
                maggTARESDichiarata = dichiarato.residuoMaggTARES
            }
            dichiarato.residuoImposta -= impostaDichiarata
            dichiarato.residuoMaggTARES -= maggTARESDichiarata
        }

        if (annoDichiarazione > 0) {
            annoDenuncia = dichiarato.annoPratica
            dataDenuncia = dichiarato.dataPratica
        }

        def parametri = [
                dataAccertamento   : accertamento.data,
                //
                annoDenuncia       : annoDenuncia,
                dataDenuncia       : dataDenuncia,
                //
                flagTardivo        : impostazioni.flagTardivo,
                interessiAl        : impostazioni.interessiAl,
                interessiDal       : impostazioni.interessiDal,
                //
                imposta            : imposta,
                impostaDichiarata  : impostaDichiarata,
                maggTARES          : maggTARES,
                maggTARESDichiarata: maggTARESDichiarata,
                deltaImposta       : imposta - (impostaDichiarata ?: 0),
                deltaMaggTARES     : maggTARES - (maggTARESDichiarata ?: 0),
        ]

        return parametri
    }

    // Lancia la procedura di calcolo delle sanzioni di accertamento ICI
    def calcolaSanzioniAccertamentoICI(Short anno, def parametri, Boolean nuovoSanzionamento, PraticaTributoDTO pratica, OggettoContribuenteDTO ogCo) {

        def messaggio = ""

        try {
            String pUtente = springSecurityService.currentUser.id

            OggettoPraticaDTO ogPr = ogCo.oggettoPratica
            ContribuenteDTO cont = ogCo.contribuente

            String flagNuovoSanzionamento = (nuovoSanzionamento) ? 'S' : 'N'
            String flagPossessoDichiarato = (parametri.flagPossessoDichiarato) ? 'S' : 'N'
            String flagIgnoraSanzioneMinima = 'S'

            Sql sql = new Sql(dataSource)

            sql.call('{ call CALCOLO_SANZIONI_ICI(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}',
                    [
                            // a_anno                    IN number
                            anno,
                            // a_data_accertamento       IN date
                            parametri.dataAccertamento,
                            // a_imposta_dovuta          IN number
                            parametri.impostaDichiarata,
                            // a_imposta_dovuta_acconto  IN number
                            parametri.impostaAccontoDichiarata,
                            // a_mesi_possesso_dic       IN number
                            parametri.mesiPossessoDichiarati,
                            // a_flag_possesso_dic       IN varchar2
                            parametri.flagPossessoDichiarato,
                            // a_importo_versato         IN number
                            parametri.importoVersato,
                            // a_imposta                 IN number
                            parametri.imposta,
                            // a_imposta_acconto         IN number
                            parametri.impostaAcconto,
                            // a_mesi_possesso           IN number
                            parametri.mesiPossesso,
                            // a_mesi_possesso_1s        IN number
                            parametri.mesiPossesso1S,
                            // a_pratica                 IN number
                            pratica.id,
                            // a_oggetto_pratica         IN number
                            ogPr.id,
                            // a_nuovo_sanzionamento     IN varchar2
                            flagNuovoSanzionamento,
                            // a_utente                  IN varchar2
                            pUtente,
                            /// a_flag_ignora_sanz_minima IN varchar2 default null
                            flagIgnoraSanzioneMinima
                    ],
                    {}
            )

            messaggio = "OK"
        }
        catch (Exception e) {
            if (e?.message?.startsWith("ORA-20999")) {
                throw new Application20999Error(e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n')))
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                throw new Application20999Error(e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n')))
            } else {
                throw e
            }
        }

        return messaggio
    }

    // Lancia la procedura di calcolo delle sanzioni di accertamento TARSU
    def calcolaSanzioniAccertamentoTARSU(Short anno, def parametri, Boolean nuovoSanzionamento, PraticaTributoDTO pratica, OggettoContribuenteDTO ogCo) {

        def messaggio = ""

        try {
            String pUtente = springSecurityService.currentUser.id

            OggettoPraticaDTO ogPr = ogCo.oggettoPratica
            ContribuenteDTO cont = ogCo.contribuente

            String flagNuovoSanzionamento = (nuovoSanzionamento) ? 'S' : 'N'

            String flagTardivo = (parametri.flagTardivo) ? 'S' : 'N'
            def interessiDal = parametri.interessiDal
            def interessiAl = parametri.interessiAl
            String flagIgnoraSanzioneMinima = 'S'

            Sql sql = new Sql(dataSource)

            sql.call('{ call CALCOLO_SANZIONI_TARSU(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}',
                    [
                            // a_cod_fiscale              IN varchar2,
                            cont.codFiscale,
                            // a_anno                     IN  number,
                            anno,
                            // a_pratica                  IN number,
                            pratica.id,
                            // a_oggetto_pratica          IN number,
                            ogPr.id,
                            // a_imposta                  IN number,
                            parametri.imposta,
                            // a_anno_denuncia            IN number,
                            parametri.annoDenuncia,
                            // a_data_denuncia            IN date,
                            parametri.dataDenuncia,
                            // a_imposta_dichiarata       IN number,
                            parametri.impostaDichiarata,
                            // a_nuovo_sanzionamento      IN varchar2,
                            flagNuovoSanzionamento,
                            // a_flag_tardivo             IN varchar2,
                            flagTardivo,
                            // a_utente                   IN varchar2,
                            pUtente,
                            // a_interessi_dal            IN date,
                            interessiDal ? new Date(interessiDal.getTime()) : null,
                            // a_interessi_al             IN date,
                            interessiAl ? new Date(interessiAl.getTime()) : null,
                            // a_imposta_magg_tares       IN number,
                            parametri.maggTARES,
                            // a_imposta_dic_magg_tares   IN number
                            parametri.maggTARESDichiarata,
                            // a_flag_ignora_sanz_minima  IN varchar2 default null
                            flagIgnoraSanzioneMinima
                    ],
                    {}
            )

            messaggio = "OK"
        }
        catch (Exception e) {
            commonService.serviceException(e)
        }

        return messaggio
    }

    // Esegue merge degli importi delle sanzioni
    def mergeSanzioniPratica(def pratica, interessiDal, interessiAl) {

        def sanzioniMerge = mergeSanzioniPraticaDati(pratica.id)

        def impostaEvasa = sanzioniMerge.find { it.tipoCausale == "E" }?.importo

        eliminaTutteLeSanzioni(pratica.id)
        pratica.sanzioniPratica = []

        PraticaTributo praticaRaw = pratica.toDomain()
        SanzionePratica sanzione

        def sanzioni = Sanzione.createCriteria().list {
            eq("tipoTributo.tipoTributo", praticaRaw.tipoTributo.tipoTributo)
        }

        sanzioniMerge.each {

            def sanzioneData = it

            sanzione = new SanzionePratica()
            sanzione.pratica = praticaRaw
            sanzione.sanzione = sanzioni.find {
                it.codSanzione == sanzioneData.codSanzione &&
                        it.sequenza == sanzioneData.sequenzaSanz
            }
            sanzione.seqSanz = sanzioneData.sequenzaSanz
            sanzione.importo = calcolaImporto(it, impostaEvasa)
            sanzione.importoLordo = sanzioneData.importoLordo
            sanzione.giorni = sanzioneData.giorni
            sanzione.note = sanzioneData.note
            sanzione.percentuale = sanzioneData.percentuale
            sanzione.riduzione = sanzioneData.riduzione
            sanzione.riduzione2 = sanzioneData.riduzione2
            sanzione.abPrincipale = sanzioneData.abPrincipale
            sanzione.rurali = sanzioneData.rurali
            sanzione.terreniComune = sanzioneData.terreniComune
            sanzione.terreniErariale = sanzioneData.terreniErariale
            sanzione.areeComune = sanzioneData.areeComune
            sanzione.areeErariale = sanzioneData.areeErariale
            sanzione.altriComune = sanzioneData.altriComune
            sanzione.altriErariale = sanzioneData.altriErariale
            sanzione.fabbricatiDComune = sanzioneData.fabbricatiDComune
            sanzione.fabbricatiDErariale = sanzioneData.fabbricatiDErariale
            sanzione.fabbricatiMerce = sanzioneData.aafabbricatiMercea

            if (sanzioneData.codSanzione == 199) {
                if ((interessiDal) && (interessiAl)) {
                    Long delta = interessiAl.getTime() - interessiDal.getTime()
                    Short giorni = Math.floor(delta / (24 * 60 * 60 * 1000)) + 1
                    sanzione.giorni = giorni
                }
            }

            sanzione.sequenza = 1
            sanzione.utente = springSecurityService.currentUser

            sanzione.save(flush: true, failOnError: true)
        }
    }

    // Ricava importi totali sanzioni pratica
    def mergeSanzioniPraticaDati(long praticaId) {

        def filtri = [:]

        filtri << ['idPratica': praticaId]

        String sql = """
                SELECT
                    SANZ.TIPO_CAUSALE,
                    SANZ.SANZIONE_MINIMA,
                    SZPR.PRATICA,
                    SZPR.COD_SANZIONE,
                    SZPR.SEQUENZA_SANZ,
                    SZPR.TIPO_TRIBUTO,
                    SZPR.PERCENTUALE,
                    SZPR.RIDUZIONE,
                    SZPR.RIDUZIONE_2,
                    CASE WHEN SZPR.IMPORTO > 0 AND NVL(SANZ.SANZIONE_MINIMA,0) > SZPR.IMPORTO THEN 
                      NVL(SANZ.SANZIONE_MINIMA,0) 
                      ELSE SZPR.IMPORTO END AS IMPORTO,
                    SZPR.IMPORTO_RUOLO,
                    SZPR.GIORNI,
                  CASE WHEN SZPR.IMPORTO > 0 AND NVL(SANZ.SANZIONE_MINIMA,0) > SZPR.IMPORTO THEN 
                        decode(SZPR.NOTE,'','',SZPR.NOTE||'; ')|| 'Sanzione minima - Totale sanzioni orig. '||to_char(SZPR.IMPORTO)
                    ELSE SZPR.NOTE END AS NOTE,
                    SZPR.AB_PRINCIPALE,
                    SZPR.RURALI,
                    SZPR.TERRENI_COMUNE,
                    SZPR.TERRENI_ERARIALE,
                    SZPR.AREE_COMUNE,
                    SZPR.AREE_ERARIALE,
                    SZPR.ALTRI_COMUNE,
                    SZPR.ALTRI_ERARIALE,
                    SZPR.FABBRICATI_D_COMUNE,
                    SZPR.FABBRICATI_D_ERARIALE,
                    SZPR.FABBRICATI_MERCE
                FROM (
                     SELECT  PRATICA,
                        COD_SANZIONE,
                        SEQUENZA_SANZ,
                        TIPO_TRIBUTO,
                        PERCENTUALE,
                        RIDUZIONE,
                        RIDUZIONE_2,
                        SUM(IMPORTO) AS IMPORTO,
                        SUM(IMPORTO_RUOLO) AS IMPORTO_RUOLO,
                        MAX(GIORNI) AS GIORNI,
                        LISTAGG(NOTE, '') WITHIN GROUP(ORDER BY NOTE) AS NOTE,
                        SUM(AB_PRINCIPALE) AS AB_PRINCIPALE,
                        SUM(RURALI) AS RURALI,
                        SUM(TERRENI_COMUNE) AS TERRENI_COMUNE,
                        SUM(TERRENI_ERARIALE) AS TERRENI_ERARIALE,
                        SUM(AREE_COMUNE) AS AREE_COMUNE,
                        SUM(AREE_ERARIALE) AS AREE_ERARIALE,
                        SUM(ALTRI_COMUNE) AS ALTRI_COMUNE,
                        SUM(ALTRI_ERARIALE) AS ALTRI_ERARIALE,
                        SUM(FABBRICATI_D_COMUNE) AS FABBRICATI_D_COMUNE,
                        SUM(FABBRICATI_D_ERARIALE) AS FABBRICATI_D_ERARIALE,
                        SUM(FABBRICATI_MERCE) AS FABBRICATI_MERCE
                     FROM SANZIONI_PRATICA
                    WHERE PRATICA = :idPratica
                      AND COD_SANZIONE BETWEEN 100 AND 199
                    GROUP BY  PRATICA,
                          COD_SANZIONE,
                          SEQUENZA_SANZ,
                          TIPO_TRIBUTO,
                          PERCENTUALE,
                          RIDUZIONE,
                          RIDUZIONE_2) SZPR,
                      SANZIONI SANZ
                WHERE SZPR.TIPO_TRIBUTO = SANZ.TIPO_TRIBUTO AND
                      SZPR.COD_SANZIONE = SANZ.COD_SANZIONE AND
                      SZPR.SEQUENZA_SANZ = SANZ.SEQUENZA
                ORDER BY  PRATICA,
                    COD_SANZIONE,
                    TIPO_TRIBUTO
		"""

        def params = [:]
        params.offset = 0
        params.max = Integer.MAX_VALUE

        def results = eseguiQuery("${sql}", filtri, params)

        def records = []

        results.each {

            def record = [:]

            record.tipoCausale = it['TIPO_CAUSALE'] as String
            record.sanzioneMinima = it['SANZIONE_MINIMA'] as BigDecimal
            record.pratica = it['PRATICA'] as Long
            record.codSanzione = it['COD_SANZIONE'] as Long
            record.sequenzaSanz = it['SEQUENZA_SANZ'] as Short
            record.tipoTributo = it['TIPO_TRIBUTO'] as String
            record.importo = it['IMPORTO'] as BigDecimal
            record.importoLordo = it['IMPORTO_LORDO'] as BigDecimal
            record.giorni = it['GIORNI'] as Short
            record.note = it['NOTE'] as String
            record.percentuale = it['PERCENTUALE'] as Double
            record.riduzione = it['RIDUZIONE'] as Double
            record.riduzione2 = it['RIDUZIONE_2'] as Double
            record.abPrincipale = it['AB_PRINCIPALE'] as BigDecimal
            record.rurali = it['RURALI'] as BigDecimal
            record.terreniComune = it['TERRENI_COMUNE'] as BigDecimal
            record.terreniErariale = it['TERRENI_ERARIALE'] as BigDecimal
            record.areeComune = it['AREE_COMUNE'] as BigDecimal
            record.areeErariale = it['AREE_ERARIALE'] as BigDecimal
            record.altriComune = it['ALTRI_COMUNE'] as BigDecimal
            record.altriErariale = it['ALTRI_ERARIALE'] as BigDecimal
            record.fabbricatiDComune = it['FABBRICATI_D_COMUNE'] as BigDecimal
            record.fabbricatiDErariale = it['FABBRICATI_D_ERARIALE'] as BigDecimal
            record.fabbricatiMerce = it['FABBRICATI_MERCE'] as BigDecimal

            records << record
        }

        return records
    }

    private def calcolaImporto(Map dati, BigDecimal impostaEvasa) {

        String tipoCausale = dati.tipoCausale
        BigDecimal sanzioneMinima = dati.sanzioneMinima ?: 0
        BigDecimal importo = dati.importo
        BigDecimal percentuale = dati.percentuale

        if (tipoCausale in ['E', 'I', 'S']) {
            return importo
        }
        else {
            if (percentuale == null) {
                return importo
            }
            else {
                BigDecimal importoTmp = impostaEvasa * percentuale / 100
                return (Math.max(sanzioneMinima, importoTmp) as BigDecimal).setScale(2, BigDecimal.ROUND_CEILING)
            }
        }
    }

    /// Aggiorna gli importi di oggetti_imposta dopo determinazione quote infedele - Ici
    def aggiornaOggettoImpostaIci(def accertato, def parametri) {

        Long ogImId = accertato.oggettoImposta

        if (ogImId) {
            Double impostaDichiarata = parametri.impostaDichiarata

            if (impostaDichiarata != null) {
                OggettoImposta ogIm = OggettoImposta.get(ogImId)
                if (ogIm == null) {
                    throw new Exception("Oggetto Imposta ${ogImId} non trovato")
                }
                ogIm.impostaDovuta = impostaDichiarata
                ogIm.impostaDovutaAcconto = parametri.impostaAccontoDichiarata
                ogIm.save(flush: true, failOnError: true)
            }
        }
    }

    /// Aggiorna gli importi di oggetti_imposta dopo determinazione quote infedele - TaRSU
    def aggiornaOggettoImpostaTARSU(def accertato, def parametri) {

        Long ogImId = accertato.oggettoImposta

        if (ogImId) {
            Double impostaDichiarata = parametri.impostaDichiarata

            if (impostaDichiarata != null) {
                OggettoImposta ogIm = OggettoImposta.get(ogImId)
                if (ogIm == null) {
                    throw new Exception("Oggetto Imposta ${ogImId} non trovato")
                }
                ogIm.impostaDovuta = impostaDichiarata
                //	ogIm.maggiorazioneTaresDovuta = parametri.maggTARESDichiarata
                ogIm.save(flush: true, failOnError: true)
            }
        }
    }

    def checkAggImmRavv(def pratica) {
        def messaggio = ""
        Sql sql = new Sql(dataSource)
        sql.call('{? = call F_CHECK_AGG_IMM_RAVV(?)}'
                , [
                Sql.VARCHAR,
                pratica
        ]) { messaggio = it }
        return messaggio
    }

    def ricalcoloInteressi(def idPratica = null) {
        try {
            Sql sql = new Sql(dataSource)

            log.info "Esecuzione: RICALCOLO_INTERESSI($idPratica)"
            sql.call("{call RICALCOLO_INTERESSI(?)}", [idPratica])

        } catch (Exception e) {
            commonService.serviceException(e)
        }
    }

    def ricalcolaSpeseNotifica(def pratiche, def params = null) {
        def subListSize = 250
        def subList = pratiche.collect { it }.collate(subListSize)

        subList.each { praticheIds ->
            createUpdateSpeseNotificaOnPratiche(praticheIds, params)
        }

    }

    private void createUpdateSpeseNotificaOnPratiche(def praticheIds, def params = null) {
        if (params?.creaSeNonPresenti && params?.sanzione == null) {
            throw new IllegalArgumentException('Impossibile aggiungere Spese Notifica se nessuna Sanzione definita')
        }
        Sanzione sanzione = params?.sanzione?.toDomain()
        SpesaNotifica spesaNotifica = params?.importo?.toDomain()

        def saprAventiSpeseNotifica = getListaSanzioniPraticaSpeseNotifica([praticheIds: praticheIds])

        if (sanzione == null) {
            saprAventiSpeseNotifica.each { sapr ->
                sapr.importo = getImporto(spesaNotifica, sapr.sanzione)
                sapr.save(flush: true, failOnError: true)
            }
            return
        }

        if (params.creaSeNonPresenti) {
            def praticheAventiSpeseNotifica = saprAventiSpeseNotifica.collect { it.pratica.id }.unique()
            def praticheSenzaSpeseNotifica = praticheIds - praticheAventiSpeseNotifica
            createSanzioniPratiche(praticheSenzaSpeseNotifica, spesaNotifica, sanzione)
        }

        def saprAventiSpesaNotificaParametro = getListaSanzioniPraticaSpeseNotifica([sanzione: sanzione, praticheIds: praticheIds])
        saprAventiSpesaNotificaParametro.each { sapr ->
            sapr.importo = getImporto(spesaNotifica, sanzione)
            sapr.save(flush: true, failOnError: true)
        }

        if (params.creaSeNonPresenti) {
            def saprAventiSpesaNotificaDiversoDaParametro = saprAventiSpeseNotifica - saprAventiSpesaNotificaParametro
            saprAventiSpesaNotificaDiversoDaParametro.each { sapr ->
                sapr.delete(flush: true, failOnError: true)
            }
            def praticheAventiSpeseNotificaDiversoDaParametro = saprAventiSpesaNotificaDiversoDaParametro.collect { it.pratica.id }.unique()
            createSanzioniPratiche(praticheAventiSpeseNotificaDiversoDaParametro, spesaNotifica, sanzione)
        }
    }

    private getListaSanzioniPraticaSpeseNotifica(def filter) {
        def queryParameters = [
                pTipoCausale: 'S',
                pPraticaList: filter.praticheIds.collect { it as Long }
        ]
        if (filter.sanzione) {
            queryParameters.pCodSanzione = filter.sanzione.codSanzione
            queryParameters.pSeqSanzione = filter.sanzione.sequenza
        }
        SanzionePratica.executeQuery("""
            select sapr
              from SanzionePratica sapr
             where sanzione.tipoCausale = :pTipoCausale
               and pratica.id in (:pPraticaList)
               ${filter.sanzione ? "and sanzione.codSanzione = :pCodSanzione" : ''}
               ${filter.sanzione ? "and sanzione.sequenza = :pSeqSanzione" : ''}
        """, queryParameters)
    }

    private getImporto(SpesaNotifica spesaNotifica, Sanzione sanzione) {
        return spesaNotifica ? spesaNotifica.importo : sanzione.sanzione
    }

    private void createSanzioniPratiche(List praticheIdsSenzaSanzioni, SpesaNotifica spesaNotifica, Sanzione sanzione) {
        praticheIdsSenzaSanzioni.each { praticaId ->
            executeInserimentoSanzione(sanzione.codSanzione, sanzione.tipoTributo.tipoTributo, praticaId, null, null, getImporto(spesaNotifica, sanzione), sanzione.sequenza)
        }
    }

    void executeInserimentoSanzione(def codSanzione, def tipoTributo, def pratica, def oggettoPratica, def maggioreImpo, def impoSanz, def sequenzaSanzione, def user = null) {
        Sql sql = new Sql(dataSource)
        sql.call('{call INSERIMENTO_SANZIONE(?, ?, ?, ?, ?, ?, ?,?)}', [
                codSanzione,
                tipoTributo,
                pratica,
                oggettoPratica,
                maggioreImpo,
                impoSanz,
                user ?: springSecurityService.currentUser.id,
                sequenzaSanzione
        ])
    }

    def getSanzioniSpeseNotificaRicalcolabili(def tipoTributo) {
        sanzioniService.getSanzioniSpeseNotificaRicalcolabili(tipoTributo)
    }

    def getSpeseNotifica(def tipoTributo) {
        speseNotificaService.getPositiveSpeseNotifica(tipoTributo)
    }

    /**
     * @deprecated
     * Sembra non essere più utilizzata. Se confermato rimuovere.
     *
     * @param idPratica
     * @return
     */
    @Deprecated()
    def passaggioAPagoPa(def idPratica = null) {
        def messaggio = ""
        try {
            Sql sql = new Sql(dataSource)

            log.info "Esecuzione: PAGONLINE_TR4.INSERIMENTO_VIOLAZIONI($idPratica)"
            sql.call('{? = call PAGONLINE_TR4.INSERIMENTO_VIOLAZIONI(?)}'
                    , [
                    Sql.NUMERIC,
                    idPratica
            ], { res ->

                log.info "Risposta da PAGONLINE_TR4.INSERIMENTO_VIOLAZIONI: ${res}"
                messaggio = res
            })


        } catch (Exception e) {
            commonService.serviceException(e)
        }
        return messaggio
    }

    // Riporta data odierna - mezzanotte
    def getDataOdierna(boolean asCalendar = false) {

        Calendar today = Calendar.getInstance()
        today.set(Calendar.HOUR_OF_DAY, 0)
        today.set(Calendar.MINUTE, 0)
        today.set(Calendar.SECOND, 0)
        today.set(Calendar.MILLISECOND, 0)

        if (!asCalendar) {
            return today.getTime()
        }

        return today
    }

    def getTipiNotifica() {
        return OggettiCache.TIPI_NOTIFICA.valore.sort { it.tipoNotifica }
    }

    // Arrotonda double
    static double round(double value, int places) {

        if (places < 0) throw new IllegalArgumentException()

        BigDecimal bd = value as BigDecimal
        bd = bd.setScale(places, RoundingMode.HALF_UP)
        return bd.doubleValue()
    }
}
