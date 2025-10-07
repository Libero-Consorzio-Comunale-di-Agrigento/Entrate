package it.finmatica.tr4.imposte

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.*
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.SpecieRuolo
import it.finmatica.tr4.commons.TipoRuolo
import it.finmatica.tr4.commons.TributiSession
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.jobs.Tr4AfcElaborazioneService
import it.finmatica.tr4.pratiche.OggettoPratica
import it.finmatica.tr4.pratiche.PraticaTributo
import oracle.jdbc.OracleTypes
import org.hibernate.criterion.CriteriaSpecification
import org.hibernate.criterion.Order
import org.hibernate.criterion.Restrictions
import org.hibernate.transform.AliasToEntityMapResultTransformer
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import transform.AliasToEntityCamelCaseMapResultTransformer

import java.sql.Date
import java.sql.ResultSet

class ImposteService {

    private Logger log = LoggerFactory.getLogger(ImposteService.class)

    CommonService commonService
    IntegrazioneDePagService integrazioneDePagService
    Tr4AfcElaborazioneService tr4AfcElaborazioneService

    static transactional = false

    def springSecurityService
    def sessionFactory

    def dataSource
    TributiSession tributiSession

    public final TIPI_FILTRO_CONTRIBUENTI = [
            TUTTI     : null,
            A_RIMBORSO: 'R',
            DA_PAGARE : 'P',
            SALDATI   : 'S'
    ]

    def getListaAnni() {
        def lista = PraticaTributo.createCriteria().list() {
            projections { distinct("anno") }
            order("anno", "desc")
        }
        lista << ""
    }

    def getListaAnniImposte(String tipoTributo) {

        def lista = OggettoImposta.createCriteria().list() {
            projections { distinct("anno") }
            if (tipoTributo) {
                eq("tipoTributo.tipoTributo", tipoTributo)
            }
            order("anno", "desc")
        }
    }

    def getListaTributi(def pAnno) {
        def lista = TipoTributo.createCriteria().list() { order("tipoTributo", "asc") }
    }

    /**
     * Riepilogo delle imposte per tipo tributo e anno
     * @param tipoTributo
     * @param anno
     * @return
     */
    def listaImposte(String tipoTributo, List<Short> anno = null, Boolean tributo = false) {

        def parametriQuery = [:]

        if (anno && !anno.empty) {
            parametriQuery.anno = anno
        }

        String filtroAnno = anno ? "ogim.anno IN :anno AND " : ""

        parametriQuery.tipoTributo = tipoTributo

        String filtroTributo = ""

        if (tipoTributo == 'TARSU') {
            filtroTributo = """
                    and (not exists
                            (select 'x' from Ruolo ruol where ruol = ogim.ruolo) or
                            (nvl(ogim.ruolo, -1) =
                            nvl(nvl(f_ruolo_totale(ogim.oggettoContribuente.contribuente.codFiscale,
                                                    ogim.anno,
                                                    ogim.tipoTributo.tipoTributo,
                                                    -1),
                                     ogim.ruolo),
                                 -1) and ruolo.invioConsorzio is not null))
		"""
        }

        String query = """
	            SELECT new Map(
					ogim.tipoTributo.tipoTributo 		AS tipoTributo,
					ogim.anno					 		AS anno,
		"""

        if (tributo) {
            query += """
					MIN(cotr)		           			AS tributo,
					case when cotr.id BETWEEN 8600 and 8699 and cotr.descrizioneCc is not null then cotr.descrizioneCc else TO_CHAR(cotr.id) end AS servizio,
			"""
        }

        query += """
					COUNT(prtr.id)              		AS totUtenze,
					COUNT(distinct ogco.contribuente)	AS totContribuenti,
					SUM(ogim.imposta)					AS importo,
					SUM(ogim.impostaErariale)			AS impostaErariale,
					SUM(ogim.impostaMini)				AS impostaMiniAnno,
					SUM(ogim.importoRuolo)				AS importoRuolo,
					SUM(COALESCE(ogim.addizionaleEca, 0) + COALESCE(ogim.maggiorazioneEca, 0)) AS addMaggEca,	
					SUM(ogim.addizionalePro)			AS addProv,	
					SUM(ogim.iva)						AS iva,		
					SUM(ogim.maggiorazioneTares)		AS maggTares
					)	
				FROM 
					PraticaTributo prtr
					INNER JOIN prtr.oggettiPratica AS ogpr   
					INNER JOIN ogpr.oggettiContribuente AS ogco  
					INNER JOIN ogco.oggettiImposta AS ogim
					LEFT JOIN ogim.ruolo AS ruolo
					LEFT JOIN ogpr.codiceTributo AS cotr
				WHERE
					${filtroAnno}
					ogim.tipoTributo.tipoTributo = :tipoTributo AND
					(
						prtr.tipoPratica in ('D', 'C') 
		                OR
						(
							prtr.tipoPratica = 'A'  AND
							ogim.anno > prtr.anno AND
							prtr.flagDenuncia = 'S'
						)
					) AND
					ogim.flagCalcolo = 'S'
					${filtroTributo}
	             GROUP BY
					ogim.anno,
					ogim.tipoTributo.tipoTributo
		"""

        if (tributo) {
            query += """
					, case when cotr.id BETWEEN 8600 and 8699 and cotr.descrizioneCc is not null then cotr.descrizioneCc else TO_CHAR(cotr.id) end
			"""
        }

        query += """
				ORDER BY
					ogim.anno DESC
		"""

        if (tributo) {
            query += """
					, MIN(cotr.id)
					, case when cotr.id BETWEEN 8600 and 8699 and cotr.descrizioneCc is not null then cotr.descrizioneCc else TO_CHAR(cotr.id) end ASC
			"""
        }

        def dati = PraticaTributo.executeQuery(query, parametriQuery)

        return dati
    }

    def listaImposteContribuenti(def anno, def tipoTributo, def parRicerca, def ordinamento,
                                 int pageSize, int activePage, def tributo = null, def servizio = null) {

	//	long startTime = System.currentTimeMillis()
		
		def lista = []
						 		 
        if (tipoTributo == "TARSU") {
            lista = listaImposteContribuentiTARSU(anno, parRicerca, ordinamento, pageSize, activePage, servizio)
        } else {
            lista = listaImposteContribuentiAltriTributi(anno, tipoTributo, parRicerca, ordinamento, pageSize, activePage, tributo, servizio)
        }

	//	long endTime = System.currentTimeMillis()
	//	println"Eseguito in " + (endTime - startTime)+ " ms"
		
		return lista
    }

    private def listaImposteContribuentiAltriTributi(def anno, def tipoTributo, def parRicerca,
                                                     def ordinamento, int pageSize, int activePage,
                                                     def tributo = null, def servizio = null) {

        String sql = ""
        String sqlPerDovuto = ""
        String sqlTotali = ""
        String sqlFiltri = ""
		
		String sqlImporti = ""

        String sqlOGVA = ""
        String sqlOGVAJoin = ""
        Boolean perValidita = false

        String tableContattiContribuente = ""

        def filtri = [:]

        filtri << ['anno': Integer.valueOf(anno)]
        filtri << ['tipoTributo': tipoTributo]

        if (tributo) {
            filtri << ['codiceTributo': tributo as Long]
            sqlFiltri += " AND OGPR.TRIBUTO = :codiceTributo "
        }
        if (servizio) {
            filtri << ['servizio': servizio as String]
            sqlFiltri += " AND CASE WHEN COTR.TRIBUTO BETWEEN 8600 AND 8699 AND COTR.DESCRIZIONE_CC IS NOT NULL "
            sqlFiltri += " THEN COTR.DESCRIZIONE_CC ELSE TO_CHAR(COTR.TRIBUTO) END = :servizio "
        }
        if (tipoTributo == 'TARSU') {
            sqlFiltri += """ AND
					(
						COALESCE(OGIM.RUOLO,-1) = COALESCE(COALESCE(f_ruolo_totale(CONT.COD_FISCALE,OGIM.ANNO,PRTR.TIPO_TRIBUTO,-1),OGIM.ruolo), -1) AND
						(
							OGIM.RUOLO IS NULL OR 
							(OGIM.RUOLO IS NOT NULL AND RUOL.INVIO_CONSORZIO IS NOT NULL)
						)
					)
			"""
        }

        if (parRicerca?.cognome) {
            filtri << ['cognome': parRicerca.cognome.toUpperCase()]
            sqlFiltri += " AND SOGG.COGNOME LIKE :cognome "
        }
        if (parRicerca?.nome) {
            filtri << ['nome': parRicerca.nome.toUpperCase()]
            sqlFiltri += " AND SOGG.NOME LIKE :nome "
        }
        if (parRicerca?.cf) {
            filtri << ['codFiscale': parRicerca.cf.toUpperCase() + '%']
            sqlFiltri += " AND CONT.COD_FISCALE LIKE :codFiscale "
        }

        if (parRicerca?.tipoContatto) {
            filtri << ['tipoContatto': parRicerca.tipoContatto]
            tableContattiContribuente = " CONTATTI_CONTRIBUENTE COCO, "
            sqlFiltri += """ 
                         AND COCO.ANNO = OGIM.ANNO 
                         AND COCO.TIPO_TRIBUTO = OGIM.TIPO_TRIBUTO 
                         AND COCO.COD_FISCALE = OGIM.COD_FISCALE
                         AND COCO.TIPO_CONTATTO = :tipoContatto
                         """
        }

        def daDataPratica = parRicerca?.daDataPratica
        if (daDataPratica) {
            filtri << ['daDataPratica': daDataPratica.format('dd/MM/yyyy')]
            sqlFiltri += " AND PRTR.DATA >= TO_DATE(:daDataPratica, 'dd/mm/yyyy') "
        }
        def aDataPratica = parRicerca?.aDataPratica
        if (aDataPratica) {
            filtri << ['aDataPratica': aDataPratica.format('dd/MM/yyyy')]
            sqlFiltri += " AND PRTR.DATA <= TO_DATE(:aDataPratica, 'dd/mm/yyyy') "
        }

        def daDataCalcolo = parRicerca?.daDataCalcolo
        if (daDataCalcolo) {
            filtri << ['daDataCalcolo': daDataCalcolo.format('dd/MM/yyyy')]
            sqlFiltri += " AND OGIM.DATA_VARIAZIONE >= TO_DATE(:daDataCalcolo, 'dd/mm/yyyy') "
        }
        def aDataCalcolo = parRicerca?.aDataCalcolo
        if (aDataCalcolo) {
            filtri << ['aDataCalcolo': aDataCalcolo.format('dd/MM/yyyy')]
            sqlFiltri += " AND OGIM.DATA_VARIAZIONE <= TO_DATE(:aDataCalcolo, 'dd/mm/yyyy') "
        }

        if (parRicerca?.tipoOccupazione) {
            filtri << ['tipoOccupazione': parRicerca.tipoOccupazione]
            sqlFiltri += " AND NVL(OGPR.TIPO_OCCUPAZIONE,'P') LIKE :tipoOccupazione "
        }

        if (parRicerca?.tipoLista) {
            if (parRicerca.tipoLista == 'P-AP') {
                sqlFiltri += " AND NVL(OGPR.TIPO_OCCUPAZIONE,'P') = 'P' AND OGVA.DAL < TO_DATE('01/01/'||:anno, 'dd/mm/yyyy') "
                perValidita = true
            }
            if (parRicerca.tipoLista == 'P-AC') {
                sqlFiltri += " AND NVL(OGPR.TIPO_OCCUPAZIONE,'P') = 'P' AND OGVA.DAL >= TO_DATE('01/01/'||:anno, 'dd/mm/yyyy') "
                perValidita = true
            }
            if (parRicerca.tipoLista == 'T-AC') {
                sqlFiltri += " AND NVL(OGPR.TIPO_OCCUPAZIONE,'P') = 'T' AND OGVA.DAL >= TO_DATE('01/01/'||:anno, 'dd/mm/yyyy') "
                perValidita = true
            }
            if (parRicerca.tipoLista == 'X-AC') {
                sqlFiltri += " AND NVL(OGPR.TIPO_OCCUPAZIONE,'P') IN ('P','T') AND OGVA.DAL >= TO_DATE('01/01/'||:anno, 'dd/mm/yyyy') "
                perValidita = true
            }
        }

        def listaParamTipoSogg = []
        if (parRicerca.personaFisica) {
            listaParamTipoSogg << "0"
        }
        if (parRicerca.personaGiuridica) {
            listaParamTipoSogg << "1"
        }
        if (parRicerca.intestazioniParticolari) {
            listaParamTipoSogg << "2"
        }

        if (!listaParamTipoSogg.empty) {
            sqlFiltri += " AND SOGG.TIPO IN (${listaParamTipoSogg.join(",")}) "
        }

        if (perValidita) {
            sqlOGVA = "OGGETTI_VALIDITA OGVA, "
            sqlOGVAJoin = "PRTR.COD_FISCALE = OGVA.COD_FISCALE AND OGPR.OGGETTO_PRATICA = OGVA.OGGETTO_PRATICA AND "
        }
		
		if(tipoTributo == 'CUNI') {
			sqlImporti = """
                    SUM(nvl(OGIM.imposta, 0)) - nvl(f_dovuto(max(CONT.ni), :anno, :tipoTributo, 0, -1, 'S', null), 0) AS IMPORTO,
                    MAX(nvl(f_tot_vers_cont(OGIM.anno, OGIM.cod_fiscale, :tipoTributo, 'V'), 0)) AS VERSATO,
                    MAX(nvl(f_tot_vers_cont(OGIM.anno, OGIM.cod_fiscale, :tipoTributo, 'T'), 0)) AS TARDIVO,
			"""
		}
		else {
			sqlImporti = """
                    0 AS IMPORTO,
                    0 AS VERSATO,
                    0 AS TARDIVO,
			"""
		}

        //Query Contribuenti base
        sql = """
				SELECT DISTINCT
					MAX(SOGG.NI) AS NI,
					TRANSLATE(SOGG.COGNOME_NOME,'/',' ') AS COGNOME_NOME,
					CONT.COD_FISCALE AS COD_FISCALE,
					SUM(NVL(OGIM.IMPOSTA,0)) AS IMPOSTA,
					SUM(NVL(OGIM.IMPOSTA_ERARIALE,0)) AS IMPOSTA_ERARIALE,
					${sqlImporti}
                    MAX(DECODE(DTGG.FLAG_INTEGRAZIONE_GSD,
                                  'S',
                                  DECODE(SOGG.TIPO_RESIDENTE,
                                         0,
                                         DECODE(SOGG.FASCIA, 1, 'SI', 3, 'NI', 'NO'),
                                         'NO'),
                                  decode(SOGG.TIPO_RESIDENTE, 0, 'SI', 'NO'))) AS RESIDENTE,
                    ANADEV.DESCRIZIONE AS STATO_DESCRIZIONE,
                    MAX(SOGG.DATA_ULT_EVE) AS DATA_ULT_EVENTO,
                    MAX(DECODE(SOGG.COD_VIA,
                                  null,
                                  SOGG.DENOMINAZIONE_VIA,
                                  ARVI.DENOM_UFF)) AS INDIRIZZO_RES,
                    MAX(SOGG.NUM_CIV ||
                           DECODE(SOGG.SUFFISSO, null, '', '/' || SOGG.SUFFISSO)) AS NUM_CIVICO_RES,
                    MAX(COMU.DENOMINAZIONE) AS COMUNE_RES,
                    MAX(LPAD(SOGG.CAP, 5, '0')) AS CAP_RES,
                    MAX(TRANSLATE(SOGG_P.COGNOME_NOME, '/', ' ')) COGNOME_NOME_P,
                    MAX(f_recapito(SOGG.NI, :tipoTributo, 3)) AS PEC_MAIL,
                    MAX(DECODE(SOGG.FASCIA,2,DECODE(SOGG.STATO,50,'',
                           DECODE(LPAD(DTGG.PRO_CLIENTE,3,'0') || LPAD(DTGG.COM_CLIENTE,3,'0'),
                           LPAD(SOGG.COD_PRO_RES,3,'0') || LPAD(SOGG.COD_COM_RES,3,'0'),'ERR','')),'')) VERIFICA_COMUNE_RES,
                    MAX(f_verifica_cap(SOGG.COD_PRO_RES,SOGG.COD_COM_RES,SOGG.CAP)) VERIFICA_CAP
				FROM
                    DATI_GENERALI DTGG,
                    ANADEV ANADEV,
                    ARCHIVIO_VIE ARVI,
                    AD4_COMUNI COMU,
					OGGETTI_PRATICA OGPR,
					PRATICHE_TRIBUTO PRTR,
					OGGETTI OGGE,
					OGGETTI_CONTRIBUENTE OGCO,
					OGGETTI_IMPOSTA OGIM,
				    ${sqlOGVA}
					CODICI_TRIBUTO COTR,
					CONTRIBUENTI CONT,
					SOGGETTI SOGG,
                    SOGGETTI SOGG_P,
                    ${tableContattiContribuente}
					RUOLI RUOL
				WHERE
                    SOGG.STATO = ANADEV.COD_EV(+) AND
                    SOGG.COD_VIA = ARVI.COD_VIA(+) AND
                    SOGG.COD_COM_RES = COMU.COMUNE(+) AND
                    SOGG.COD_PRO_RES = COMU.PROVINCIA_STATO(+) AND
                    SOGG.NI_PRESSO = SOGG_P.NI(+) AND
				    OGPR.PRATICA = PRTR.PRATICA AND
				    OGPR.OGGETTO = OGGE.OGGETTO AND
				    OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA AND
				    OGCO.COD_FISCALE = CONT.COD_FISCALE AND
				    OGIM.COD_FISCALE = OGCO.COD_FISCALE AND
				    OGPR.OGGETTO_PRATICA = OGIM.OGGETTO_PRATICA AND
				    OGPR.TRIBUTO = COTR.TRIBUTO(+) AND
				    ${sqlOGVAJoin}
				    CONT.NI = SOGG.NI AND
				    OGIM.RUOLO = RUOL.RUOLO (+) AND
				    OGIM.FLAG_CALCOLO = 'S' AND
					(
						PRTR.TIPO_PRATICA IN ('D', 'C') OR
						(
							PRTR.TIPO_PRATICA = 'A' AND
							OGIM.ANNO > PRTR.ANNO  AND
							PRTR.FLAG_DENUNCIA = 'S'
						)
					) AND
					OGIM.ANNO = :anno AND
					OGIM.TIPO_TRIBUTO IN (:tipoTributo)
					${sqlFiltri}
				GROUP BY
					SOGG.COGNOME_NOME,
					CONT.COD_FISCALE,
                    ANADEV.DESCRIZIONE
		"""

        switch (ordinamento.tipo) {
            case CampiOrdinamento.CONTRIBUENTE:
                if (ordinamento.ascendente) {
                    sql += """
				ORDER BY
					2, 3
				"""
                } else {
                    sql += """
				ORDER BY
					2 DESC, 3 DESC
				"""
                }
                break
            case CampiOrdinamento.CF:
                if (ordinamento.ascendente) {
                    sql += """
				ORDER BY
					3, 2
				"""
                } else {
                    sql += """
				ORDER BY
					3 DESC, 2 DESC
				"""
                }
                break
            case CampiOrdinamento.IMPOSTA:
                if (ordinamento.ascendente) {
                    sql += """
				ORDER BY
					4, 3, 2
				"""
                } else {
                    sql += """
				ORDER BY
					4 DESC, 3, 2
				"""
                }
                break
            default:
                break
        }

        //Query per tab A Rimborso, Da Pagare, Saldati Caso CUNI
        if (parRicerca.nomeTabImposte && tipoTributo == "CUNI") {
            if (parRicerca.nomeTabImposte == TIPI_FILTRO_CONTRIBUENTI.A_RIMBORSO) {
                sqlPerDovuto = """
                        SELECT * 
                        FROM ($sql)
                        WHERE VERSATO - IMPORTO > ${tributiSession.dovSoglia}
                """
            } else if (parRicerca.nomeTabImposte == TIPI_FILTRO_CONTRIBUENTI.DA_PAGARE) {
                sqlPerDovuto = """
                        SELECT * 
                        FROM ($sql)
                        WHERE VERSATO - IMPORTO < ${tributiSession.dovSoglia}
                """
            } else if (parRicerca.nomeTabImposte == TIPI_FILTRO_CONTRIBUENTI.SALDATI) {
                sqlPerDovuto = """
                        SELECT * 
                        FROM ($sql)
                        WHERE VERSATO - IMPORTO BETWEEN ${-tributiSession.dovSoglia} AND ${tributiSession.dovSoglia}
				"""
            }
        }
		
		String sqlFinale = sqlPerDovuto.isEmpty() ? sql : sqlPerDovuto

		sqlTotali = """
			SELECT
				COUNT(*) OVER() AS TOTAL_COUNT,
				SUM(IMPOSTA) OVER() AS TOTAL_IMPOSTA,
				SUM(IMPOSTA_ERARIALE) OVER() AS TOTAL_IMPOSTA_ERARIALE,
                SUM(IMPORTO) OVER() AS TOTAL_IMPORTO,
                SUM(VERSATO) OVER() AS TOTAL_VERSATO,
                SUM(TARDIVO) OVER() AS TOTAL_TARDIVO,
                SUM(IMPORTO) OVER() - SUM(VERSATO) OVER() AS TOTAL_DOVUTO,
                IMPO.*
			FROM (${sqlFinale}) IMPO
		"""

        def params = [:]
        params.max = pageSize ?: 25
        params.activePage = activePage ?: 0
        params.offset = params.activePage * params.max

        def results = eseguiQuery(sqlTotali, filtri, params)
		
		def totals = [ totalCount : 0 ]
		
        def records = []
		
		if (!results.empty) {
			
			def result = results[0]
			
			totals = [
				totalCount          : result['TOTAL_COUNT'],
				totalImposta        : result['TOTAL_IMPOSTA'],
				totalImpostaErariale: result['TOTAL_IMPOSTA_ERARIALE'],
				totalImporto        : result['TOTAL_IMPORTO'],
				totalVersato        : result['TOTAL_VERSATO'],
				totalTardivo        : result['TOTAL_TARDIVO'],
				totalDovuto         : result['TOTAL_DOVUTO']
			]
			
			results.each {
				
				def record = [:]
	
				record.ni = it['NI']
	
				record.contribuente = it['COGNOME_NOME']
				record.codFiscale = it['COD_FISCALE']
				record.imposta = it['IMPOSTA']
				record.impostaErariale = it['IMPOSTA_ERARIALE']
				record.importo = it["IMPORTO"]
				record.tardivo = it["TARDIVO"]
				record.versato = it["VERSATO"]
				record.dovuto = (record.importo ?: 0) - (record.versato ?: 0)
				record.residente = it['RESIDENTE'] == 'SI'
				record.statoDescrizione = it['STATO_DESCRIZIONE']
				record.dataUltEvento = it['DATA_ULT_EVENTO']
				record.indirizzoRes = it['INDIRIZZO_RES']
				record.civicoRes = it['NUM_CIVICO_RES']
				record.comuneRes = it['COMUNE_RES']
				record.capRes = it['CAP_RES']
				record.cognomeNomeP = it['COGNOME_NOME_P']
				record.mailPec = it['PEC_MAIL']
				record.comuneResErr = it['VERIFICA_COMUNE_RES']
				record.capResErr = it['VERIFICA_CAP']
	
				records << record
			}
		}
		
        return [totalCount: totals.totalCount, totals: totals, records: records]
    }

    private def listaImposteContribuentiTARSU(def anno, def parRicerca, def ordinamento,
                                              int pageSize, int activePage, def servizio = null) {

        String sql = ""
        String sql2 = ""
        String sqlTotali = ""
        String sqlFiltri = ""

        String tableContattiContribuente = ""

        def filtri = [:]

        filtri << ['anno': Integer.valueOf(anno)]
        filtri << ['tipoTributo': 'TARSU']

        if (servizio) {
            filtri << ['servizio': servizio as String]
            sqlFiltri += " AND CASE WHEN imru.TRIBUTO BETWEEN 8600 AND 8699 AND imru.DESCRIZIONE_CC IS NOT NULL "
            sqlFiltri += " THEN imru.DESCRIZIONE_CC ELSE TO_CHAR(imru.TRIBUTO) END = :servizio "
        }

        if (parRicerca?.cognome) {
            filtri << ['cognome': parRicerca.cognome.toUpperCase()]
            sqlFiltri += " AND sogg.COGNOME LIKE :cognome "
        }
        if (parRicerca?.nome) {
            filtri << ['nome': parRicerca.nome.toUpperCase()]
            sqlFiltri += " AND sogg.NOME LIKE :nome "
        }
        if (parRicerca?.cf) {
            filtri << ['codFiscale': parRicerca.cf.toUpperCase() + '%']
            sqlFiltri += " AND conx.COD_FISCALE LIKE :codFiscale "
        }

        if (parRicerca?.tipoContatto) {
            filtri << ['tipoContatto': parRicerca.tipoContatto]
            tableContattiContribuente = " CONTATTI_CONTRIBUENTE coco, "
            sqlFiltri += """
                         AND coco.anno = imru.anno
                         AND coco.tipo_tributo = 'TARSU'
                         AND coco.cod_fiscale = conx.cod_fiscale 
                         AND coco.tipo_contatto = :tipoContatto
                         """
        }

        def daDataPratica = parRicerca?.daDataPratica
        if (daDataPratica) {
            filtri << ['daDataPratica': daDataPratica.format('dd/MM/yyyy')]
            sqlFiltri += " AND imru.DATA >= TO_DATE(:daDataPratica, 'dd/mm/yyyy') "
        }
        def aDataPratica = parRicerca?.aDataPratica
        if (aDataPratica) {
            filtri << ['aDataPratica': aDataPratica.format('dd/MM/yyyy')]
            sqlFiltri += " AND imru.DATA <= TO_DATE(:aDataPratica, 'dd/mm/yyyy') "
        }

        def daDataCalcolo = parRicerca?.daDataCalcolo
        if (daDataCalcolo) {
            filtri << ['daDataCalcolo': daDataCalcolo.format('dd/MM/yyyy')]
            sqlFiltri += " AND imru.DATA_VARIAZIONE >= TO_DATE(:daDataCalcolo, 'dd/mm/yyyy') "
        }
        def aDataCalcolo = parRicerca?.aDataCalcolo
        if (aDataCalcolo) {
            filtri << ['aDataCalcolo': aDataCalcolo.format('dd/MM/yyyy')]
            sqlFiltri += " AND imru.DATA_VARIAZIONE <= TO_DATE(:aDataCalcolo, 'dd/mm/yyyy') "
        }

        if (parRicerca?.tipoLista) {
            if (parRicerca.tipoLista == 'P-AP') {
                sqlFiltri += " AND NVL(imru.TIPO_OCCUPAZIONE,'P') = 'P' AND OGVA.DAL < TO_DATE('01/01/'||:anno, 'dd/mm/yyyy') "
            }
            if (parRicerca.tipoLista == 'P-AC') {
                sqlFiltri += " AND NVL(imru.TIPO_OCCUPAZIONE,'P') = 'P' AND OGVA.DAL >= TO_DATE('01/01/'||:anno, 'dd/mm/yyyy') "
            }
            if (parRicerca.tipoLista == 'T-AC') {
                sqlFiltri += " AND NVL(imru.TIPO_OCCUPAZIONE,'P') = 'T' AND OGVA.DAL >= TO_DATE('01/01/'||:anno, 'dd/mm/yyyy') "
            }
            if (parRicerca.tipoLista == 'X-AC') {
                sqlFiltri += " AND NVL(imru.TIPO_OCCUPAZIONE,'P') IN ('P','T') AND OGVA.DAL >= TO_DATE('01/01/'||:anno, 'dd/mm/yyyy') "
            }
        }

        def listaParamTipoSogg = []
        if (parRicerca.personaFisica) {
            listaParamTipoSogg << "0"
        }
        if (parRicerca.personaGiuridica) {
            listaParamTipoSogg << "1"
        }
        if (parRicerca.intestazioniParticolari) {
            listaParamTipoSogg << "2"
        }

        if (!listaParamTipoSogg.empty) {
            sqlFiltri += " AND SOGG.TIPO IN (${listaParamTipoSogg.join(",")}) "
        }

        // Valori default
        filtri.ruolo = filtri.ruolo ?: 0
        filtri.codFiscale = filtri.codFiscale ?: '%'
        filtri.tributo = filtri.tribuo ?: -1

        sql = """   
                select count(*) over() as TOTAL_COUNT,
                   SUM(IMPOSTA_RUOLO) over() AS TOTAL_IMPOSTA_RUOLO,
                   SUM(SGRAVIO_TOT) over() AS TOTAL_SGRAVIO_TOT,
                   SUM(VERSATO) over() AS TOTAL_VERSATO,
                   SUM(IMPOSTA) over() AS TOTAL_IMPOSTA,
                   SUM(ADD_MAGG_ECA) over() AS TOTAL_ADD_MAGG_ECA,
                   SUM(ADDIZIONALE_PRO) over() AS TOTAL_ADDIZIONALE_PRO,
                   SUM(IVA) over() AS TOTAL_IVA,
                   SUM(IMPORTO_PF) over() AS TOTAL_IMPORTO_PF,
                   SUM(IMPORTO_PV) over() AS TOTAL_IMPORTO_PV,
                   SUM(MAGGIORAZIONE_TARES) over() AS TOTAL_MAGGIORAZIONE_TARES,
                   SUM(NVl(IMPOSTA_RUOLO, 0) - NVl(VERSATO, 0) - NVl(SGRAVIO_TOT, 0)) over() AS TOTAL_DOVUTO,
                   impo.*
                from (SELECT imru1.cod_fiscale,
                       round(nvl(imru1.imposta_ruolo, 0) -
                       nvl(Nvl(F_tot_vers_cont_ruol(imru1.anno,
                                                    imru1.cod_fiscale,
                                                    :tipoTributo,
                                                    Decode(Nvl(:ruolo, 0), 0, NULL, :ruolo),
                                                    'V'),
                               0),
                           0) - nvl(imru1.sgravio_tot, 0)) as dovuto,
                       imru1.anno anno,
                       imru1.ruolo,
                       imru1.imposta_ruolo imposta_ruolo,
                       SUM(imru1.imposta) imposta,
                       SUM(imru1.imposta_lorda) imposta_lorda,
                       Nvl(SUM(imru1.iva), 0) iva,
                       Nvl(SUM(imru1.importo_pf), 0) importo_pf,
                       Nvl(SUM(imru1.importo_pv), 0) importo_pv,
                       Nvl(SUM(imru1.add_magg_eca), 0) add_magg_eca,
                       SUM(imru1.addizionale_pro) addizionale_pro,
                       SUM(imru1.maggiorazione_tares) maggiorazione_tares,
                       SUM(imru1.importo_sgravio) importo_sgravio,
                       Nvl(SUM(imru1.maggiorazione_eca_sgravio), 0) add_magg_eca_sgravio,
                       SUM(imru1.addizionale_pro_sgravio) addizionale_pro_sgravio,
                       SUM(imru1.maggiorazione_tares_sgravio) maggiorazione_tares_sgravio,
                       SUM(imru1.sgravio_tot) sgravio_tot,
                       nvl(Nvl(F_tot_vers_cont_ruol(imru1.anno,
                                                    imru1.cod_fiscale,
                                                    :tipoTributo,
                                                    Decode(Nvl(:ruolo, 0), 0, NULL, :ruolo),
                                                    'V'),
                               0),
                           0) versato,
                       Nvl(F_tot_vers_cont_ruol(imru1.anno,
                                                imru1.cod_fiscale,
                                                :tipoTributo,
                                                Decode(Nvl(:ruolo, 0), 0, NULL, :ruolo),
                                                'VN'),
                           0) versato_netto,
                       Nvl(F_tot_vers_cont_ruol(imru1.anno,
                                                imru1.cod_fiscale,
                                                :tipoTributo,
                                                Decode(Nvl(:ruolo, 0), 0, NULL, :ruolo),
                                                'V'),
                           0) -
                       Nvl(F_tot_vers_cont_ruol(imru1.anno,
                                                imru1.cod_fiscale,
                                                :tipoTributo,
                                                Decode(Nvl(:ruolo, 0), 0, NULL, :ruolo),
                                                'VN'),
                           0) versato_maggiorazione,
                       SUM(imru1.imposta_ruolo) -
                       Nvl(F_tot_vers_cont_ruol(imru1.anno,
                                                imru1.cod_fiscale,
                                                :tipoTributo,
                                                Decode(Nvl(:ruolo, 0), 0, NULL, :ruolo)),
                           0) - Nvl(SUM(sgravio_tot), 0) differenza,
                       Max(csoggnome) csoggnome,
                       Max(indirizzo_dich) indirizzo_dich,
                       Max(residenza_dich) residenza_dich,
                       Max(cognome) cognome,
                       Max(nome) nome,
                       max(tributo),
                       max(titr),
                       ni,
                       residente,
                       max(dataUltEvento) data_ult_evento,
                       max(indirizzo_res) indirizzo_res,
                       max(civico_res) civico_res,
                       max(comune_res) comune_res,
                       max(cap_res) cap_res,
                       max(mail_pec) mail_pec,
                       max(cognome_nome_p) cognome_nome_p,
                       max(stato_descrizione) stato_descrizione,
                       max(verifica_comune_res) comune_res_err,
                       max(verifica_cap) cap_res_err
                  FROM (select distinct imru.cod_fiscale_imru as cod_fiscale,
                                        imru.ruolo,
                                        imru.anno,
                                        imru.imposta_ruolo imposta_ruolo,
                                        imru.imposta imposta,
                                        imru.imposta_lorda imposta_lorda,
                                        imru.addizionale_eca addizionale_eca,
                                        nvl(sgra.importo_sgravio, 0) importo_sgravio,
                                        Nvl(sgra.addizionale_eca_sgravio, 0) addizionale_eca_sgravio,
                                        Nvl(sgra.iva_sgravio, 0) iva_sgravio,
                                        Nvl(sgra.maggiorazione_eca_sgravio, 0) maggiorazione_eca_sgravio,
                                        nvl(sgra.addizionale_pro_sgravio, 0) addizionale_pro_sgravio,
                                        nvl(sgra.maggiorazione_tares_sgravio, 0) maggiorazione_tares_sgravio,
                                        nvl(sgra.sgravio_tot, 0) sgravio_tot,
                                        Nvl(imru.iva, 0) iva,
                                        Nvl(imru.importo_pf, 0) importo_pf,
                                        Nvl(imru.importo_pv, 0) importo_pv,
                                        Nvl(imru.addizionale_eca, 0) + Nvl(imru.iva, 0) +
                                        Nvl(imru.maggiorazione_eca, 0) add_magg_eca,
                                        imru.addizionale_pro addizionale_pro,
                                        imru.maggiorazione_tares maggiorazione_tares,
                                        nvl(Nvl(F_tot_vers_cont_ruol(imru.anno,
                                                                     conx.cod_fiscale,
                                                                     :tipoTributo,
                                                                     Decode(Nvl(:ruolo, 0),
                                                                            0,
                                                                            NULL,
                                                                            :ruolo),
                                                                     'V'),
                                                0),
                                            0) versato,
                                        Nvl(F_tot_vers_cont_ruol(imru.anno,
                                                                 conx.cod_fiscale,
                                                                 :tipoTributo,
                                                                 Decode(Nvl(:ruolo, 0),
                                                                        0,
                                                                        NULL,
                                                                        :ruolo),
                                                                 'VN'),
                                            0) versato_netto,
                                        Nvl(F_tot_vers_cont_ruol(imru.anno,
                                                                 conx.cod_fiscale,
                                                                 :tipoTributo,
                                                                 Decode(Nvl(:ruolo, 0),
                                                                        0,
                                                                        NULL,
                                                                        :ruolo),
                                                                 'V'),
                                            0) -
                                        Nvl(F_tot_vers_cont_ruol(imru.anno,
                                                                 conx.cod_fiscale,
                                                                 :tipoTributo,
                                                                 Decode(Nvl(:ruolo, 0),
                                                                        0,
                                                                        NULL,
                                                                        :ruolo),
                                                                 'VN'),
                                            0) versato_maggiorazione,
                                        TRANSLATE(sogg.cognome_nome, '/', ' ') csoggnome,
                                        Decode(sogg.cod_via,
                                               NULL,
                                               sogg.denominazione_via,
                                               arvi.denom_uff) ||
                                        Decode(sogg.num_civ, NULL, '', ', ' || sogg.num_civ) ||
                                        Decode(sogg.suffisso, NULL, '', '/' || sogg.suffisso) indirizzo_dich,
                                        Decode(Nvl(sogg.cap, comu.cap),
                                               NULL,
                                               '',
                                               Nvl(sogg.cap, comu.cap) || ' ') ||
                                        comu.denominazione ||
                                        Decode(prov.sigla,
                                               NULL,
                                               '',
                                               ' (' || prov.sigla || ')') residenza_dich,
                                        Upper(Replace(sogg.cognome, ' ', '')) cognome,
                                        Upper(Replace(sogg.nome, ' ', '')) nome,
                                        To_number(:tributo) tributo,
                                        Rpad(:tipoTributo, 5, ' ') titr,
                                        conx.ni ni,
                                        DECODE(DTGG.FLAG_INTEGRAZIONE_GSD,
                                                                  'S',
                                                                  DECODE(SOGG.TIPO_RESIDENTE,
                                                                         0,
                                                                         DECODE(SOGG.FASCIA, 1, 'SI', 3, 'NI', 'NO'),
                                                                         'NO'),
                                                                  decode(SOGG.TIPO_RESIDENTE, 0, 'SI', 'NO')) residente,
                                        SOGG.DATA_ULT_EVE dataUltEvento,
                                        DECODE(SOGG.COD_VIA,
                                                                  null,
                                                                  SOGG.DENOMINAZIONE_VIA,
                                                                  arvi.DENOM_UFF) indirizzo_res,
                                        SOGG.NUM_CIV ||
                                                       DECODE(SOGG.SUFFISSO, null, '', '/' || SOGG.SUFFISSO) AS civico_res,
                                        comu.DENOMINAZIONE comune_res,
                                        LPAD(SOGG.CAP, 5, '0') cap_res,
                                        f_recapito(SOGG.NI, 'TARSU', 3) mail_pec,
                                        TRANSLATE(SOGG_P.COGNOME_NOME, '/', ' ') cognome_nome_p,
                                        ANADEV.DESCRIZIONE stato_descrizione,
                                        DECODE(SOGG.FASCIA,2,DECODE(SOGG.STATO,50,'',
                                                DECODE(LPAD(DTGG.PRO_CLIENTE,3,'0') || LPAD(DTGG.COM_CLIENTE,3,'0'),
                                                        LPAD(SOGG.COD_PRO_RES,3,'0') || LPAD(SOGG.COD_COM_RES,3,'0'),'ERR','')),'') verifica_comune_res,
                                        f_verifica_cap(SOGG.COD_PRO_RES,SOGG.COD_COM_RES,SOGG.CAP) verifica_cap
                          FROM OGGETTI_PRATICA OGPR,
                               PRATICHE_TRIBUTO PRTR,
                               OGGETTI OGGE,
                               OGGETTI_contRIBUENTE OGCO,
                               OGGETTI_IMPOSTA OGIM,
                               CODICI_TRIBUTO COTR,
                               contribuenti conx,
                               SOGGETTI SOGG,
                               SOGGETTI SOGG_P,
                               RUOLI RUOL,
                               archivio_vie arvi,
                               ad4_comuni comu,
                               ad4_provincie prov,
                               DATI_GENERALI DTGG,
                               ANADEV ANADEV,
                               ${tableContattiContribuente}
                               (select ni,
                                       cod_fiscale_imru,
                                       sum(imposta_ruolo) imposta_ruolo,
                                       SUM(importo_pf) importo_pf,
                                       SUM(importo_pv) importo_pv,
                                       SUM(imposta) imposta,
                                       SUM(addizionale_eca) addizionale_eca,
                                       SUM(maggiorazione_eca) maggiorazione_eca,
                                       SUM(addizionale_pro) addizionale_pro,
                                       SUM(iva) iva,
                                       SUM(maggiorazione_tares) maggiorazione_tares,
                                       sum(imposta_lorda) as imposta_lorda,
                                       anno,
                                       max(oggetto_pratica) id_ogpr1,
                                       max(TIPO_OCCUPAZIONE) tipo_occupazione,
                                       max(data_variazione) data_variazione,
                                       max(data) data,
                                       max(tributo) tributo,
                                       max(DESCRIZIONE_CC) DESCRIZIONE_CC,
                                       case
                                         when max(nRuoli) > 1 then
                                          null
                                         else
                                          max(ruolo)
                                       end ruolo
                                  from (SELECT conx1.cod_fiscale,
                                               ogim1.ruolo,
                                               count(distinct ogim1.ruolo) over() as nRuoli,
                                               conx1.ni,
                                               ogim1.cod_fiscale cod_fiscale_imru,
                                               ogim1.imposta +
                                                     Nvl(ogim1.addizionale_eca, 0) +
                                                     Nvl(ogim1.maggiorazione_eca, 0) + (CASE
                                                       WHEN :anno <= 2020 THEN
                                                        Nvl(ogim1.addizionale_pro, 0)
                                                       ELSE
                                                        0
                                                     END) + Nvl(ogim1.iva, 0) +
                                               Nvl(ogim1.maggiorazione_tares, 0) +
                                               (CASE
                                                  WHEN :anno > 2020 THEN
                                                   Nvl(ogim1.addizionale_pro, 0)
                                                  ELSE
                                                   0
                                                END) imposta_ruolo,
                                               ogim1.importo_pf,
                                               ogim1.importo_pv,
                                               ogim1.imposta,
                                               ogim1.addizionale_eca,
                                               ogim1.maggiorazione_eca,
                                               ogim1.addizionale_pro,
                                               ogim1.iva,
                                               ogim1.maggiorazione_tares,
                                               Round(ogim1.imposta +
                                                     Nvl(ogim1.addizionale_eca, 0) +
                                                     Nvl(ogim1.maggiorazione_eca, 0) +
                                                     Nvl(ogim1.addizionale_pro, 0) +
                                                     Nvl(ogim1.iva, 0),
                                                     0) imposta_lorda,
                                               ogim1.anno,
                                               ogpr1.oggetto_pratica,
                                               ogpr1.TIPO_OCCUPAZIONE,
                                               ogim1.data_variazione,
                                               prtr1.data,
                                               cotr1.tributo,
                                               cotr1.DESCRIZIONE_CC
                                          FROM pratiche_tributo prtr1,
                                               tipi_tributo     titr1,
                                               codici_tributo   cotr1,
                                               oggetti_pratica  ogpr1,
                                               oggetti_imposta  ogim1,
                                               ruoli            ruol1,
                                               contribuenti     conx1,
											   (select
							                        to_number(substr(unique_date_code,-10)) as ruolo_totale,
							                        cod_fiscale
							                      from
							                        (select
							                            max(to_char(ruoli.data_emissione,'YYYYMMDDHH24MISS') || to_char(ruoli.ruolo,'fm0000000000')) as unique_date_code,
							                            ruco.cod_fiscale
							                          from ruoli,
							                               ruoli_contribuente ruco
							                         where ((ruoli.tipo_emissione is null) or (ruoli.tipo_emissione = 'T'))
							                               and ruoli.ruolo = ruco.ruolo
										   				   and ruoli.tipo_tributo = :tipoTributo
							                               and ruoli.anno_ruolo = :anno
										   				   and :anno >= 2013
							                               and ((:tributo = -1) or 
							                                   ((:tributo != -1) and (ruco.tributo is not null) and (ruco.tributo = :tributo)))
							                               and ruoli.invio_consorzio is not null
							                               and ruoli.specie_ruolo = 0
							                          group by cod_fiscale)) ruto
                                         WHERE titr1.tipo_tributo = cotr1.tipo_tributo
                                           AND cotr1.tributo = ogpr1.tributo + 0
                                           AND cotr1.tipo_tributo = prtr1.tipo_tributo || ''
                                           AND prtr1.tipo_tributo || '' = :tipoTributo
                                           AND prtr1.cod_fiscale || '' = ogim1.cod_fiscale
                                           AND prtr1.pratica = ogpr1.pratica
                                           AND ogpr1.oggetto_pratica = ogim1.oggetto_pratica
                                           AND ogpr1.tributo =
                                               Decode(:tributo, -1, ogpr1.tributo, :tributo)
                                           AND ogim1.ruolo IS NOT NULL
                                           AND ogim1.flag_calcolo = 'S'
                                           AND ogim1.anno = :anno
							   			   --
							   			   and ogim1.cod_fiscale = ruto.cod_fiscale(+) 
                                           AND ogim1.ruolo =
                                               Nvl(Nvl(Decode(:ruolo, 0, To_number(''), :ruolo),
                                                       ruto.ruolo_totale),
                                                   ogim1.ruolo)
							   			   --
                                           AND ogim1.cod_fiscale LIKE :codFiscale
                                           AND ruol1.ruolo = ogim1.ruolo
                                           AND ruol1.invio_consorzio IS NOT NULL
                                           and conx1.cod_fiscale = ogim1.cod_fiscale)
                                 group by ni, cod_fiscale_imru, anno) imru,
                               (SELECT SUM(Nvl(sgrx.importo, 0) -
                                       Nvl(sgrx.addizionale_eca, 0) -
                                       Nvl(sgrx.maggiorazione_eca, 0) -
                                       Nvl(sgrx.addizionale_pro, 0) - Nvl(sgrx.iva, 0) -
                                       Nvl(sgrx.maggiorazione_tares, 0)) importo_sgravio,
                                   SUM(sgrx.addizionale_eca) addizionale_eca_sgravio,
                                   SUM(sgrx.maggiorazione_eca) maggiorazione_eca_sgravio,
                                   SUM(sgrx.addizionale_pro) addizionale_pro_sgravio,
                                   SUM(sgrx.iva) iva_sgravio,
                                   SUM(sgrx.maggiorazione_tares) maggiorazione_tares_sgravio,
                                   SUM(Nvl(sgrx.importo, 0)) sgravio_tot,
                                   max(sgrx.cod_fiscale) cod_fiscale_sgra
                              FROM sgravi           sgrx,
                                   pratiche_tributo prtr1,
                                   tipi_tributo     titr1,
                                   codici_tributo   cotr1,
                                   oggetti_pratica  ogpr1,
                                   oggetti_imposta  ogim1,
                                   ruoli            ruol1,
                                   contribuenti     conx1,
								   (select
				                        to_number(substr(unique_date_code,-10)) as ruolo_totale,
				                        cod_fiscale
				                      from
				                        (select
				                            max(to_char(ruoli.data_emissione,'YYYYMMDDHH24MISS') || to_char(ruoli.ruolo,'fm0000000000')) as unique_date_code,
				                            ruco.cod_fiscale
				                          from ruoli,
				                               ruoli_contribuente ruco
				                         where ((ruoli.tipo_emissione is null) or (ruoli.tipo_emissione = 'T'))
				                               and ruoli.ruolo = ruco.ruolo
							   				   and ruoli.tipo_tributo = :tipoTributo
				                               and ruoli.anno_ruolo = :anno
							   				   and :anno >= 2013
				                               and ((:tributo = -1) or 
				                                   ((:tributo != -1) and (ruco.tributo is not null) and (ruco.tributo = :tributo)))
				                               and ruoli.invio_consorzio is not null
				                               and ruoli.specie_ruolo = 0
				                          group by cod_fiscale)) ruto
                             WHERE titr1.tipo_tributo = cotr1.tipo_tributo
                               AND cotr1.tributo = ogpr1.tributo + 0
                               AND cotr1.tipo_tributo = prtr1.tipo_tributo || ''
                               AND prtr1.tipo_tributo || '' = :tipoTributo
                               AND prtr1.cod_fiscale || '' = ogim1.cod_fiscale
                               AND prtr1.pratica = ogpr1.pratica
                               AND ogpr1.oggetto_pratica = ogim1.oggetto_pratica
                               AND ogpr1.tributo =
                                   Decode(:tributo, -1, ogpr1.tributo, :tributo)
                               AND ogim1.ruolo IS NOT NULL
                               AND ogim1.flag_calcolo = 'S'
                               AND ogim1.anno = :anno
							   --
							   and ogim1.cod_fiscale = ruto.cod_fiscale(+) 
                               AND ogim1.ruolo =
                                   Nvl(Nvl(Decode(:ruolo, 0, To_number(''), :ruolo),
                                           ruto.ruolo_totale),
                                       ogim1.ruolo)
							   --
                               AND ogim1.cod_fiscale LIKE :codFiscale
                               AND ruol1.ruolo = ogim1.ruolo
                               AND ruol1.invio_consorzio IS NOT NULL
                               and conx1.cod_fiscale = ogim1.cod_fiscale
                               and sgrx.cod_Fiscale = ogim1.cod_fiscale
                               and sgrx.ruolo = ogim1.ruolo
							   and ((sgrx.ogpr_sgravio is null) or (sgrx.ogpr_sgravio = ogpr1.oggetto_pratica))
                             group by sgrx.cod_fiscale) sgra,
							   (select
			                        to_number(substr(unique_date_code,-10)) as ruolo_totale,
			                        cod_fiscale
			                      from
			                        (select
			                            max(to_char(ruoli.data_emissione,'YYYYMMDDHH24MISS') || to_char(ruoli.ruolo,'fm0000000000')) as unique_date_code,
			                            ruco.cod_fiscale
			                          from ruoli,
			                               ruoli_contribuente ruco
			                         where ((ruoli.tipo_emissione is null) or (ruoli.tipo_emissione = 'T'))
			                               and ruoli.ruolo = ruco.ruolo
						   				   and ruoli.tipo_tributo = :tipoTributo
			                               and ruoli.anno_ruolo = :anno
						   				   and :anno >= 2013
			                               and ((:tributo = -1) or 
			                                   ((:tributo != -1) and (ruco.tributo is not null) and (ruco.tributo = :tributo)))
			                               and ruoli.invio_consorzio is not null
			                               and ruoli.specie_ruolo = 0
			                          group by cod_fiscale)) ruto
                         WHERE OGPR.PRATICA = PRTR.PRATICA
                           AND OGPR.OGGETTO = OGGE.OGGETTO
                           AND OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA
                           AND OGCO.COD_FISCALE = conx.COD_FISCALE
                           AND OGIM.COD_FISCALE = OGCO.COD_FISCALE
                           AND OGPR.OGGETTO_PRATICA = OGIM.OGGETTO_PRATICA
                           AND OGPR.TRIBUTO = COTR.TRIBUTO(+)
                           AND conx.NI = SOGG.NI
                           AND OGIM.RUOLO = RUOL.RUOLO(+)
                           and sogg.cod_via = arvi.cod_via(+)
                           AND comu.provincia_stato = prov.provincia(+)
                           AND sogg.cod_pro_res = comu.provincia_stato(+)
                           AND sogg.cod_com_res = comu.comune(+)
                           AND OGIM.FLAG_CALCOLO = 'S'
                           AND (PRTR.TIPO_PRATICA IN ('D', 'C') OR
                               (PRTR.TIPO_PRATICA = 'A' AND OGIM.ANNO > PRTR.ANNO AND
                               PRTR.FLAG_DENUNCIA = 'S'))
						   and ogim.cod_fiscale = ruto.cod_fiscale(+)
                           and (not exists
                                (select 'x' from ruoli ruolx where ruolx.ruolo = ogim.ruolo) or
                                (nvl(ogim.ruolo, -1) = nvl(nvl(ruto.ruolo_totale,
                                                               ogim.ruolo),
                                                           -1) and
                                ruol.invio_consorzio is not null))
                           AND OGIM.ANNO = :anno
                           AND OGIM.TIPO_TRIBUTO IN (:tipoTributo)
                           and imru.cod_fiscale_imru(+) = conx.cod_fiscale
                           and sgra.cod_fiscale_sgra(+) = conx.cod_fiscale
                           and conx.cod_fiscale like :codFiscale
                           AND SOGG.NI_PRESSO = SOGG_P.NI(+)
                           AND SOGG.STATO = ANADEV.COD_EV(+)
                            ${sqlFiltri}) imru1
                 group by imru1.ni,
                          imru1.anno,
                          imru1.cod_fiscale,
                          imru1.imposta_ruolo,
                          imru1.sgravio_tot,
                          imru1.ruolo,
                          imru1.residente) impo
                    """


        switch (ordinamento.tipo) {
            case CampiOrdinamento.CONTRIBUENTE:
                if (ordinamento.ascendente) {
                    sql += """
				ORDER BY
					cod_fiscale, csoggnome
				"""
                } else {
                    sql += """
				ORDER BY
					cod_fiscale, csoggnome DESC
				"""
                }
                break
            case CampiOrdinamento.CF:
                if (ordinamento.ascendente) {
                    sql += """
				ORDER BY
					csoggnome, cod_fiscale
				"""
                } else {
                    sql += """
				ORDER BY
					csoggnome DESC, cod_fiscale DESC
				"""
                }
                break
            case CampiOrdinamento.IMPOSTA:
                if (ordinamento.ascendente) {
                    sql += """
				ORDER BY
					imposta, csoggnome, cod_fiscale
				"""
                } else {
                    sql += """
				ORDER BY
					imposta DESC, csoggnome, cod_fiscale
				"""
                }
                break
            default:
                break
        }

        //Query per tab A Rimborso, Da Pagare, Saldati Caso CUNI
        if (parRicerca.nomeTabImposte) {
            if (parRicerca.nomeTabImposte == TIPI_FILTRO_CONTRIBUENTI.A_RIMBORSO) {
                sql2 = """
                        SELECT * 
                        FROM ($sql)
                        WHERE dovuto < ${-tributiSession.dovSoglia}
                        """
            } else if (parRicerca.nomeTabImposte == TIPI_FILTRO_CONTRIBUENTI.DA_PAGARE) {
                sql2 = """
                        SELECT * 
                        FROM ($sql)
                        WHERE dovuto > ${tributiSession.dovSoglia}
                        """
            } else if (parRicerca.nomeTabImposte == TIPI_FILTRO_CONTRIBUENTI.SALDATI) {
                sql2 = """
                        SELECT * 
                        FROM ($sql)
                        WHERE dovuto BETWEEN ${-tributiSession.dovSoglia} AND ${tributiSession.dovSoglia}
                        """
            }
        }

        def params = [:]
        params.max = pageSize ?: 25
        params.activePage = activePage ?: 0
        params.offset = params.activePage * params.max

        def results = sessionFactory.currentSession.createSQLQuery(parRicerca.nomeTabImposte == TIPI_FILTRO_CONTRIBUENTI.TUTTI ? sql : sql2).with {

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            filtri.each { k, v ->
                setParameter(k, v)
            }

            setFirstResult(params.offset)
            setMaxResults(params.max)

            list()
        }

        results.each {
            it.residente = it.residente == "SI"
        }

        def totals = [:]
        if (!results.empty) {
            totals << results[0]
                    .findAll { it.key.startsWith("total") }
            // .collectEntries { [(it.key): it.value] }
        } else {
            totals.totalCount = 0
        }

        return [totalCount: totals.totalCount, totals: totals, records: results]
    }

    def listaImposteDettaglio(def anno, def tipoTributo, def parRicerca, def ordinamento, int pageSize, int activePage, def tributo = null, def servizio = null) {

        def pCategoria = 0
        def pTributo = 0
        def pTipoOccupazione = null

        def whereDettaglioImposta = {
            createAlias("codiceTributo", "cotr", CriteriaSpecification.LEFT_JOIN)
            createAlias("oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
            createAlias("ogge.archivioVie", "arvi_ogge", CriteriaSpecification.LEFT_JOIN)
            createAlias("ogge.riferimentiOggetto", "riog", CriteriaSpecification.LEFT_JOIN,
                    Restrictions.sqlRestriction("TO_DATE('31/12/" + anno +
                            "','dd/mm/yyyy') BETWEEN {alias}.inizio_validita (+) AND {alias}.fine_validita (+)"))
            createAlias("oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
            createAlias("ogco.oggettiImposta", "ogim", CriteriaSpecification.INNER_JOIN)
            createAlias("pratica", "prtr", CriteriaSpecification.INNER_JOIN)
            createAlias("prtr.contribuente", "cont", CriteriaSpecification.INNER_JOIN)
            createAlias("cont.soggetto", "sogg", CriteriaSpecification.INNER_JOIN)

            //		createAlias("prtr.oggettiPratica", "ogpr", CriteriaSpecification.LEFT_JOIN)
            createAlias("tariffa", "tari", CriteriaSpecification.LEFT_JOIN)
            createAlias("tari.categoria", "cate", CriteriaSpecification.LEFT_JOIN)

            if (tipoTributo == 'TARSU') {
                createAlias("ogim.ruolo", "ruolo", CriteriaSpecification.LEFT_JOIN)
                sqlRestriction("""
							 (COALESCE(ogim6_.ruolo, -1) =
				               COALESCE(COALESCE(f_ruolo_totale(cont8_.cod_fiscale,
				                                                 ogim6_.anno,
				                                                 prtr7_.tipo_tributo,
				                                                 -1),
				                                  ogim6_.ruolo),
				                         -1) AND
				               (ogim6_.ruolo is null OR (ogim6_.ruolo is not null AND
				               ruolo12_.invio_consorzio is not null)))
				""")
            }

            eq("ogim.anno", (short) anno)
            eqProperty("id", "ogim.oggettoContribuente.oggettoPratica.id")
            eq("ogim.flagCalcolo", "S")

            eq("ogim.tipoTributo.tipoTributo", tipoTributo)

            if (pTipoOccupazione) {
                sqlRestriction("COALESCE({alias}.tipo_occupazione,'P') LIKE COALESCE(${pTipoOccupazione},'%')")
            }

            if (parRicerca?.daDataDecorrenza != null) {
                ge("ogco.dataDecorrenza", parRicerca?.daDataDecorrenza)
            }
            if (parRicerca?.aDataDecorrenza != null) {
                le("ogco.dataDecorrenza", parRicerca?.aDataDecorrenza)
            }
            if (parRicerca?.daDataCessazione != null) {
                ge("ogco.dataCessazione", parRicerca?.daDataCessazione)
            }
            if (parRicerca?.aDataCessazione != null) {
                le("ogco.dataCessazione", parRicerca?.aDataCessazione)
            }

            if (parRicerca?.tipoLista == 'P-AP') {
                sqlRestriction("COALESCE({alias}.tipo_occupazione,'P') = 'P' and ogco5_.data_decorrenza < TO_DATE('01/01/" + anno + "','dd/mm/yyyy')")
            }
            if (parRicerca?.tipoLista == 'P-AC') {
                sqlRestriction("COALESCE({alias}.tipo_occupazione,'P') = 'P' and ogco5_.data_decorrenza >= TO_DATE('01/01/" + anno + "','dd/mm/yyyy')")
            }
            if (parRicerca?.tipoLista == 'T-AC') {
                sqlRestriction("COALESCE({alias}.tipo_occupazione,'P') = 'T' and ogco5_.data_decorrenza >= TO_DATE('01/01/" + anno + "','dd/mm/yyyy')")
            }
            if (parRicerca?.tipoLista == 'X-AC') {
                sqlRestriction("COALESCE({alias}.tipo_occupazione,'P') in ('P','T') and ogco5_.data_decorrenza >= TO_DATE('01/01/" + anno + "','dd/mm/yyyy')")
            }

            or {
                and {
                    'in'("prtr.tipoPratica", ["D", "C"])
                }
                and {
                    eq("prtr.tipoPratica", "A")
                    eq("prtr.flagDenuncia", "S")
                    gtProperty("ogim.anno", "prtr.anno")
                }
            }

            if (parRicerca?.personaFisica != null && parRicerca?.personaGiuridica != null && parRicerca?.intestazioniParticolari != null) {

                def listaParamTipoSogg = []
                if (parRicerca.personaFisica) {
                    listaParamTipoSogg << "0"
                }
                if (parRicerca.personaGiuridica) {
                    listaParamTipoSogg << "1"
                }
                if (parRicerca.intestazioniParticolari) {
                    listaParamTipoSogg << "2"
                }

                if (listaParamTipoSogg.size() == 1) {
                    eq("sogg.tipo", listaParamTipoSogg[0])
                } else if (listaParamTipoSogg.size() == 2) {
                    or {
                        and {
                            eq("sogg.tipo", listaParamTipoSogg[0])
                        }
                        and {
                            eq("sogg.tipo", listaParamTipoSogg[1])
                        }
                    }
                }
            }

            if (parRicerca?.cognome) {
                ilike("sogg.cognome", parRicerca?.cognome + "%")
            }
            if (parRicerca?.nome) {
                ilike("sogg.nome", parRicerca?.nome + "%")
            }
            if (parRicerca?.cf) {
                ilike("cont.codFiscale", parRicerca?.cf + "%")
            }
            if (parRicerca?.indirizzo) {
                or {
                    ilike("ogge.indirizzoLocalita", "%" + parRicerca?.indirizzo + "%")
                    ilike("arvi_ogge.denomUff", "%" + parRicerca?.indirizzo + "%")
                }
            }
            if (parRicerca?.numeroCivico) {
                eq("ogge.numCiv", Integer.valueOf(parRicerca.numeroCivico))
            }
            if (parRicerca?.suffisso) {
                ilike("ogge.suffisso", "%" + parRicerca?.suffisso + "%")
            }
            if (parRicerca?.interno) {
                ilike("ogge.interno", "%" + parRicerca?.interno + "%")
            }
            if (parRicerca?.sezione) {
                ilike("ogge.sezione", "%" + parRicerca?.sezione + "%")
            }
            if (parRicerca?.foglio) {
                ilike("ogge.foglio", "%" + parRicerca?.foglio + "%")
            }
            if (parRicerca?.numero) {
                ilike("ogge.numero", "%" + parRicerca?.numero + "%")
            }
            if (parRicerca?.subalterno) {
                ilike("ogge.subalterno", "%" + parRicerca?.subalterno + "%")
            }

            if (tributo) {
                sqlRestriction("{alias}.tributo = ${tributo}")
            }
            if (servizio) {
                sqlRestriction("CASE WHEN cotr1_.tributo BETWEEN 8600 AND 8699 AND cotr1_.descrizione_cc IS NOT NULL " +
                        "THEN cotr1_.descrizione_cc ELSE TO_CHAR(cotr1_.tributo) END = '${servizio}'")
            }
        }

        def lista = OggettoPratica.createCriteria().list {
            whereDettaglioImposta.delegate = delegate
            whereDettaglioImposta()

            projections {
                property("ogge.id")                                    // 0
                property("sogg.cognomeNome")                        // 1
                property("cont.codFiscale")                            // 2
                property("ogim.imposta")                            // 3
                property("ogge.sezione")                            // 4
                property("ogge.foglio")                                // 5
                property("ogge.numero")                                // 6
                property("ogge.subalterno")                            // 7
                property("ogge.zona")                                // 8
                property("ogge.protocolloCatasto")                    // 9
                property("ogge.annoCatasto")                        // 10
                property("categoriaCatasto.categoriaCatasto")        // 11
                property("ogge.categoriaCatasto.categoriaCatasto")    // 12
                property("classeCatasto")                            // 13
                property("ogge.classeCatasto")                        // 14
                property("ogim.impostaErariale")                    // 15
                property("ogco.percPossesso")                        // 16
                property("valore")                                    // 17
                property("tipoOggetto.tipoOggetto")                    // 18
                property("ogge.tipoOggetto.tipoOggetto")            // 19
                property("ogco.anno")                                // 20
                property("riog.categoriaCatasto")                    // 21
                property("categoriaCatasto.categoriaCatasto")        // 22
                property("ogge.categoriaCatasto.categoriaCatasto")    // 23
                property("prtr.tipoPratica")                        // 24
                property("flagValoreRivalutato")                    // 25
                property("riog.rendita")                            // 26
                property("immStorico")                                // 27
                property("ogim.tipoAliquota.tipoAliquota")            // 28
                property("ogim.aliquota")                            // 29
                property("ogim.detrazione")                            // 30
                property("ogim.detrazioneFigli")                    // 31
                property("ogge.indirizzoLocalita")                    // 32
                property("ogge.numCiv")                                // 33
                property("ogge.suffisso")                            // 34
                property("arvi_ogge.denomUff")                        // 35
                property("tipoOccupazione")                            // 36
                property("ogco.tipoRapporto")                        // 37
                property("consistenza")                                // 38
                property("ogim.id")                                    // 39
                property("prtr.id")                                    // 40
                property("sogg.id")                                    // 41
                property("ogge.descrizione")                           // 42
                property("ogco.dataDecorrenza")                        // 43
                property("ogco.dataCessazione")                        // 44
                property("cotr.id")                                       // 45
                property("cate.descrizione")                           // 46
                property("tari.descrizione")                           // 47
                property("flagContenzioso")                       // 48
                property("quantita")                                   // 49
                property("larghezza")                               // 50
                property("profondita")                               // 51
                property("consistenzaReale")                           // 52
                property("ogge.partita")                               //53
                property("ogge.progrPartita")                           //54
                property("ogim.addizionaleEca")                       //55
                property("ogim.maggiorazioneEca")                     //56
                property("ogim.iva")                                   //57
                property("ogim.maggiorazioneTares")                   //58
                property("ogim.addizionalePro")                       //59
                property("tari.tipoTariffa")                          //60
                property("ogco.flagPossesso")                          //61
                property("ogco.flagEsclusione")                          //62
                property("ogco.flagRiduzione")                          //63
                property("ogco.flagAbPrincipale")                          //64
                property("flagValoreRivalutato")                          //65
                property("categoria")                          //66
            }

            switch (ordinamento.tipo) {
                case CampiOrdinamento.OGGETTO:
                    if (ordinamento.ascendente) {
                        order("ogge.id", "asc")
                        order(Order.asc("sogg.cognomeNome").ignoreCase())
                        order("cont.codFiscale", "asc")
                        order("ogim.imposta", "asc")
                    } else {
                        order("ogge.id", "desc")
                        order("sogg.cognomeNome", "desc")
                        order("cont.codFiscale", "desc")
                        order("ogim.imposta", "desc")
                    }
                    break
                case CampiOrdinamento.CONTRIBUENTE:
                    if (ordinamento.ascendente) {
                        order(Order.asc("sogg.cognomeNome").ignoreCase())
                        order("cont.codFiscale", "asc")
                        order("ogge.id", "asc")
                        order("ogim.imposta", "asc")
                    } else {
                        order(Order.asc("sogg.cognomeNome").ignoreCase())
                        order("cont.codFiscale", "desc")
                        order("ogge.id", "desc")
                        order("ogim.imposta", "desc")
                    }
                    break
                case CampiOrdinamento.CF:
                    if (ordinamento.ascendente) {
                        order("cont.codFiscale", "asc")
                        order(Order.asc("sogg.cognomeNome").ignoreCase())
                        order("ogge.id", "asc")
                        order("ogim.imposta", "asc")
                    } else {
                        order("cont.codFiscale", "desc")
                        order(Order.asc("sogg.cognomeNome").ignoreCase())
                        order("ogge.id", "desc")
                        order("ogim.imposta", "desc")
                    }
                    break
                case CampiOrdinamento.IMPOSTA:
                    if (ordinamento.ascendente) {
                        order("ogim.imposta", "asc")
                        order(Order.asc("sogg.cognomeNome").ignoreCase())
                        order("cont.codFiscale", "asc")
                        order("ogge.id", "asc")
                    } else {
                        order("ogim.imposta", "desc")
                        order(Order.asc("sogg.cognomeNome").ignoreCase())
                        order("cont.codFiscale", "desc")
                        order("ogge.id", "desc")
                    }
                    break
                default:
                    break
            }

            firstResult(pageSize * activePage)
            maxResults(pageSize)
        }.collect { row ->
            [id                     : row[0]
             , contribuente         : row[1].replace("/", " ")
             , codFiscale           : row[2]
             , imposta              : row[3]
             , indirizzoCompleto    : (row[35] == null ? row[32] : row[35]) + " " + (row[33] == null ? "" : ", " + row[33]) + (row[34] == null ? "" : "/" + row[34]) != "null " ?
                    (row[35] == null ? row[32] : row[35]) + " " + (row[33] == null ? "" : ", " + row[33]) + (row[34] == null ? "" : "/" + row[34]) : " "
             , sez                  : row[4]
             , foglio               : row[5]
             , numero               : row[6]
             , sub                  : row[7]
             , zona                 : row[8]
             , numProtocollo        : row[9]
             , annoProtocollo       : row[10]
             , categoriaCatasto     : (row[11] != null ? row[11] : row[12])
             , classe               : (row[13] != null ? row[13] : row[14])
             , impostaErariale      : (row[15] == null) ? 0 : row[15]
             , percPossesso         : row[16]
             , valoreDichiarato     : getValore(anno, row[17], row[18], row[19], row[20], row[21]?.categoriaCatasto ?: null, row[22], row[23], row[24], row[25])
             , valoreRiog           : getValoreDaRendita(anno, row[26], row[18], row[19], row[21]?.categoriaCatasto ?: null, row[22], row[23], row[27])
             , storico              : row[27]
             , tipoAliquota         : row[28]
             , aliquota             : row[29]
             , detrazioneTotale     : (row[30] == null) ? 0 : row[30]
             , detrazioneFigliTotale: (row[31] == null) ? 0 : row[31]
             , tipoOccupazione      : row[36]
             , tipoRapporto         : row[37]
             , consistenza          : row[38]
             , oggettoImposta       : row[39]
             , praticaBase          : row[40]
             , ni                   : row[41]
             , uniqueId             : row[41].toString() + '_' + row[40].toString()
             , descrizione          : row[42]
             , dataDecorrenza       : row[43]
             , dataCessazione       : row[44]
             , codiceTributo        : row[45]
             , categoriaDescr       : row[46]
             , tariffaDescr         : row[47]
             , esenzione            : row[48]
             , quantita             : row[49]
             , larghezza            : row[50]
             , profondita           : row[51]
             , consistenzaReale     : row[52]
             , partita              : row[53]
             , progrPartita         : row[54]
             , addMaggEca           : (row[55] ?: 0) + (row[56] ?: 0)
             , addProvinciale       : row[59] ?: 0
             , iva                  : row[57] ?: 0
             , maggTares            : row[58] ?: 0
             , tipoTariffa          : row[60] ?: ''
             , indirizzo            : row[35] != null ? row[35] : row[32]
             , numCivico            : row[33] != null ? row[33] : ''
             , suffisso             : row[34] != null ? row[34] : ''
             , tipoOggetto          : row[19] != null ? row[19] + ' - ' + TipoOggetto.get(row[19]).descrizione : ''
             , flagPossesso         : row[61]
             , flagEsclusione       : row[62]
             , flagRiduzione        : row[63]
             , flagAbPrincipale     : row[64]
             , flagRivalutato       : row[65]
             , categoria            : row[66] != null ? row[66].categoria + " - " + row[66].descrizione : ''
             , tipoTariffaDesc      : row[60] != null && row[47] != null ? row[60] + " - " + row[47] : ''
             , domestica            : row[66] != null ? row[66].flagDomestica == 'S' : false
            ]
        }

        def totals = (pageSize == Integer.MAX_VALUE ? [] : OggettoPratica.createCriteria().list() {
            whereDettaglioImposta.delegate = delegate
            whereDettaglioImposta()

            projections {
                groupProperty("ogco.oggettoPratica.id")
                sum("ogim.imposta")  //1
                sum("ogim.impostaErariale")  //2
                sum("ogim.detrazione") //3
                sum("ogim.detrazioneFigli")  //4
                sum("ogim.addizionaleEca")  //5
                sum("ogim.maggiorazioneEca")  //6
                sum("ogim.addizionalePro")  //7
                sum("ogim.iva")  //8
                sum("ogim.maggiorazioneTares")  //9
            }
        })

        def totalCount = totals.size()
        def impostaTotale = totals.sum { it[1] ?: 0 }
        def impostaErarialeTotale = totals.sum { it[2] ?: 0 }
        def detrazioneTotale = totals.sum { it[3] ?: 0 }
        def detrazioneFigliTotale = totals.sum { it[4] ?: 0 }
        def addMaggECATotale = totals.sum { (it[5] ?: 0) + (it[6] ?: 0) }
        def addProvTotale = totals.sum { it[7] ?: 0 }
        def ivaTotale = totals.sum { it[8] ?: 0 }
        def maggTaresTotale = totals.sum { it[9] ?: 0 }


        // Si ottiene una lista di tutti gli NI dei soggetti presenti nella lista dei dettagli,
        // la condizione sugli NI viene generata dal metodo getCondizioneNISoggetti
        def niList = lista.collect {
            "'$it.ni'"
        }.unique()

        def CONDIZIONE_ELENCO_NI = getCondizioneNISoggetti(niList, 999)

        def sql = """
                       SELECT /*+ INDEX(SOGG SOGGETTI_PK) */
                        SOGG.ni AS NI,
                        DECODE(DTGG.FLAG_INTEGRAZIONE_GSD,
                              'S',
                              DECODE(SOGG.TIPO_RESIDENTE,
                                     0,
                                     DECODE(SOGG.FASCIA, 1, 'SI', 3, 'NI', 'NO'),
                                     'NO'),
                              decode(SOGG.TIPO_RESIDENTE, 0, 'SI', 'NO')) AS RESIDENTE,
                       ANADEV.DESCRIZIONE AS STATO_DESCRIZIONE,
                       SOGG.DATA_ULT_EVE AS DATA_ULT_EVENTO,
                       DECODE(SOGG.COD_VIA, null, SOGG.DENOMINAZIONE_VIA, ARVI.DENOM_UFF) AS INDIRIZZO_RES,
                       SOGG.NUM_CIV || DECODE(SOGG.SUFFISSO, null, '', '/' || SOGG.SUFFISSO) AS NUM_CIVICO_RES,
                       COMU.DENOMINAZIONE AS COMUNE_RES,
                       LPAD(SOGG.CAP, 5, '0') AS CAP_RES,
                       TRANSLATE(SOGG_P.COGNOME_NOME, '/', ' ') COGNOME_NOME_P,
                       f_recapito(SOGG.NI, '${tipoTributo}', 3) AS PEC_MAIL,
                       DECODE(SOGG.FASCIA,2,DECODE(SOGG.STATO,50,'',
                              DECODE(LPAD(DTGG.PRO_CLIENTE,3,'0') || LPAD(DTGG.COM_CLIENTE,3,'0'), 
                                     LPAD(SOGG.COD_PRO_RES,3,'0') || LPAD(SOGG.COD_COM_RES,3,'0'),'ERR','')
                              ),'') verifica_comune_res,
                       f_verifica_cap(SOGG.COD_PRO_RES,SOGG.COD_COM_RES,SOGG.CAP) verifica_cap
                  FROM SOGGETTI      SOGG,
                       SOGGETTI      SOGG_P,
                       ARCHIVIO_VIE  ARVI,
                       DATI_GENERALI DTGG,
                       ANADEV ANADEV,
                       AD4_COMUNI COMU
                 WHERE SOGG.ni_presso = SOGG_P.ni(+)
                       and SOGG.COD_VIA = ARVI.COD_VIA(+)
                       ${CONDIZIONE_ELENCO_NI}
                       and SOGG.STATO = ANADEV.COD_EV(+)
                       and SOGG.COD_VIA = ARVI.COD_VIA(+)
                       and SOGG.COD_COM_RES = COMU.COMUNE(+)
                       and SOGG.COD_PRO_RES = COMU.PROVINCIA_STATO(+)
                    """

        log.debug '***************************************************************************************************'
        log.debug sql
        log.debug '***************************************************************************************************'

        def dettagliSoggetto = eseguiQuery(sql, null, [:], true)

        // Vengono aggiunte le informazioni del soggetto alla lista dei dettagli in base al legame su NI
        dettagliSoggetto.each { dettSogg ->
            lista.each { dettaglio ->
                if (dettSogg.NI == dettaglio.ni) {

                    dettaglio.residente = dettSogg['RESIDENTE'] == 'SI'
                    dettaglio.statoDescrizione = dettSogg['STATO_DESCRIZIONE']
                    dettaglio.dataUltEvento = dettSogg['DATA_ULT_EVENTO']
                    dettaglio.indirizzoRes = dettSogg['INDIRIZZO_RES']
                    dettaglio.civicoRes = dettSogg['NUM_CIVICO_RES']
                    dettaglio.comuneRes = dettSogg['COMUNE_RES']
                    dettaglio.capRes = dettSogg['CAP_RES']
                    dettaglio.cognomeNomeP = dettSogg['COGNOME_NOME_P']
                    dettaglio.mailPec = dettSogg['PEC_MAIL']
                    dettaglio.comuneResErr = dettSogg['VERIFICA_COMUNE_RES']
                    dettaglio.capResErr = dettSogg['VERIFICA_CAP']
                }
            }
        }

        return [
                total                : totalCount,
                result               : lista,
                impostaTotale        : impostaTotale,
                impostaErarialeTotale: impostaErarialeTotale,
                detrazioneTotale     : detrazioneTotale,
                detrazioneFigliTotale: detrazioneFigliTotale,
                addMaggECATotale     : addMaggECATotale,
                addProvTotale        : addProvTotale,
                ivaTotale            : ivaTotale,
                maggTaresTotale      : maggTaresTotale
        ]

    }


    private def getCondizioneNISoggetti(def lista, def maxSize) {

        // Per la condizione "and Sogg.ni in (...)" bisogna verificare che la dimensione della lista non superi 1000
        // altrimenti il db lancia l'errore "ORA-01795: il numero massimo di espressioni in un elenco è 1000"
        // Nel caso la dimensione superi la soglia, vengono create delle partizioni della lista e vengono poste in OR alla condizione

        if (!lista) {
            return ""
        }

        def listaPartizioni = lista.collate(maxSize)

        if (listaPartizioni.size() == 0) {
            return ""
        }

        if (listaPartizioni.size() == 1) {
            return "and SOGG.ni in (${listaPartizioni[0].join(',')})"
        }

        if (listaPartizioni.size() > 1) {
            def condizione = ""

            for (int i = 0; i < listaPartizioni.size(); i++) {

                // Bisogna distinguere la prima partizione, da quelle intermedie e dall'ultima
                // in quanto tutta la condizione restituita deve essere contenuta dentro le parentesi -> "and (...)"
                // altrimenti viene generato un errore causa condizione in OR e OUTER_JOIN della query principale

                if (i == 0) {
                    //Prima partizione
                    condizione += "and (SOGG.ni in (${listaPartizioni[i].join(',')})"
                } else if (i == listaPartizioni.size() - 1) {
                    // Ultima partizione
                    condizione += " or SOGG.ni in (${listaPartizioni[i].join(',')}))"
                } else {
                    // Partizioni intermedie
                    condizione += " or SOGG.ni in (${listaPartizioni[i].join(',')})"
                }
            }

            return condizione
        }
    }

    def listaImpostePerCategoria(def anno, def tipoTributo, def tributo) {

        def lista = []
        def listaA = []
        def listaB = []
        def listaPaginata = []
        def totalCount = []
        def totalCountA = []
        def totalCountB = []

        def parametriQuery = [:]

        parametriQuery.pAnno = (short) anno
        parametriQuery.pTributo = tipoTributo

        String sqlA = """
			SELECT
				  COALESCE(ogpr.categoriaCatasto.categoriaCatasto, ogge.categoriaCatasto.categoriaCatasto) AS categoria
				, COALESCE(f_descrizione_caca(COALESCE(ogpr.categoriaCatasto.categoriaCatasto, ogge.categoriaCatasto.categoriaCatasto)), 
																											'IMMOBILI - CATEGORIA ASSENTE') AS des
				, MAX(ogim.anno) AS anno
				, SUM(ogim.imposta) AS imposta_anno
				, COUNT(*) AS numero
				, MAX(f_descrizione_titr(ogim.tipoTributo.tipoTributo, :pAnno)) AS des_titr  
			FROM
				OggettoPratica AS ogpr   
				INNER JOIN ogpr.pratica AS prtr   
				INNER JOIN ogpr.oggetto AS ogge  
				INNER JOIN ogpr.oggettiContribuente AS ogco  
				INNER JOIN ogco.oggettiImposta AS ogim   
			WHERE
					ogim.flagCalcolo = 'S'   
				AND COALESCE(ogpr.tipoOggetto, ogge.tipoOggetto) != 2  
				AND ogim.anno = :pAnno  
				AND ''||ogim.tipoTributo.tipoTributo in (:pTributo)  
				AND (
					prtr.tipoPratica in ('D', 'C')
					OR (
							prtr.tipoPratica = 'A'  
						AND ogim.anno > prtr.anno  
						AND prtr.flagDenuncia = 'S'
					)
				)
		"""

        if (tributo) {
            sqlA += """
				AND ogpr.codiceTributo.id = ${tributo}
		"""
        }

        sqlA += """
			GROUP BY COALESCE(ogpr.categoriaCatasto.categoriaCatasto, ogge.categoriaCatasto.categoriaCatasto)  
			ORDER BY 1,	2
		"""

        listaA = OggettoPratica.executeQuery(sqlA, parametriQuery).collect { row ->
            [codiceCategoria       : (row[0] == null) ? " " : row[0]
             , descrizioneCategoria: row[1]
             , anno                : (row[2] == null) ? anno : row[2]
             , tributo             : (row[5] == null) ? " " : row[5]
             , imposta             : (row[3] == null) ? 0 : row[3]
            ]
        }

        String sqlB = """
			SELECT
				  '' AS categoria
				, 'AREE FABBRICABILI' AS des
				, max(ogim.anno) AS anno
				, sum(ogim.imposta) AS imposta_anno
				, count(*) AS numero
				, max(f_descrizione_titr(ogim.tipoTributo.tipoTributo, :pAnno)) AS des_titr        
			FROM
				OggettoPratica AS ogpr         
				INNER JOIN ogpr.pratica AS prtr         
				INNER JOIN ogpr.oggetto AS ogge         
				INNER JOIN ogpr.oggettiContribuente AS ogco        
				INNER JOIN ogco.oggettiImposta AS ogim        
			WHERE
					ogim.flagCalcolo = 'S'         
				AND COALESCE(ogpr.tipoOggetto,ogge.tipoOggetto) = 2        
				AND ogim.anno = :pAnno        
				AND ogim.tipoTributo.tipoTributo in (:pTributo)        
				AND (
					prtr.tipoPratica in ('D', 'C')
					OR (
							prtr.tipoPratica = 'A'        
						AND ogim.anno > prtr.anno        
						AND prtr.flagDenuncia='S'
					)
				)
		"""

        if (tributo) {
            sqlB += """
				AND ogpr.codiceTributo.id = ${tributo}
		"""
        }

        sqlB += """	        
			ORDER BY 1,2
		"""

        listaB = OggettoPratica.executeQuery(sqlB, parametriQuery).collect { row ->
            [codiceCategoria       : (row[0] == null) ? " " : row[0]
             , descrizioneCategoria: row[1]
             , anno                : (row[2] == null) ? anno : row[2]
             , tributo             : (row[5] == null) ? " " : row[5]
             , imposta             : (row[3] == null) ? 0 : row[3]
            ]
        }

        // concateno le liste (UNION)
        lista += listaA
        lista += listaB

        //listaPaginata = paginazioneLista(lista, pageSize, activePage)
        //return [total: lista.size(), result: lista]

        return lista
    }

    def listaImpostePerAliquota(def anno, def tipoTributo, def tributo) {

        def parametriQuery = [:]

        parametriQuery.pAnno = (short) anno
        parametriQuery.pTributo = tipoTributo

        String sqlA = """
			SELECT
				new Map(ogim.aliquota AS aliquota
				, MAX(COALESCE(tial.descrizione, '(Aliquote Multiple)')) AS descrizione
				, tial.tipoAliquota AS tipoAliquota
				, MAX(ogim.anno) AS anno
				, SUM(ogim.imposta) AS imposta
				, COUNT(*) AS numero)
			FROM
				OggettoPratica AS ogpr       
				INNER JOIN ogpr.pratica AS prtr          
				INNER JOIN ogpr.oggettiContribuente AS ogco         
				INNER JOIN ogco.oggettiImposta AS ogim          
				LEFT JOIN ogim.tipoAliquota AS tial          
			WHERE
				ogim.flagCalcolo='S'          
				AND (
						prtr.tipoPratica in ('D','C')
					OR (
							prtr.tipoPratica = 'A'         
						AND ogim.anno > prtr.anno         
						AND prtr.flagDenuncia = 'S'
					)
				)         
				AND ogim.anno = :pAnno         
				AND ogim.tipoTributo.tipoTributo in (:pTributo)         
		"""

        if (tributo) {
            sqlA += """
				AND ogpr.codiceTributo.id = ${tributo}
		"""
        }

        sqlA += """
			GROUP BY ogim.aliquota, tial.tipoAliquota         
			ORDER BY ogim.aliquota, tial.tipoAliquota
		"""

        def dettaglioAliquote = OggettoPratica.executeQuery(sqlA, parametriQuery)

        def ab = dettaglioAliquote.groupBy { it.aliquota }.collect { row ->
            if (row.value.size() > 1) {
                [aliquota   : row.key, descrizione: "Totale Aliquota ${row.key}%", totaleImposta: row.value.sum {
                    it.imposta
                }, dettaglio: row.value]
            } else {
                [aliquota: row.key, descrizione: row.value[0].descrizione, totaleImposta: row.value[0].imposta, dettaglio: []]
            }
        }

        return ab
    }


    def listaImpostePerAliquotaCategorie(def anno, def tipoTributo, def tributo) {

        def param = [
                "p_anno"        : anno,
                "p_tipo_tributo": tipoTributo,
        ]

        def tributoWhere = tributo ? " AND ogpr.tributo = ${tributo} " : ""

        def sql = """
                   select nvl(nvl(ogpr.categoria_catasto,ogge.categoria_catasto),'!!') ordinamento,
                   nvl(ogpr.categoria_catasto,ogge.categoria_catasto) categoria,
                   nvl(f_descrizione_caca(nvl(ogpr.categoria_catasto,ogge.categoria_catasto)),
                       'IMMOBILI - CATEGORIA ASSENTE') des,
                   ogim.aliquota aliquota,
                   max(ogim.anno) anno,
                   sum(decode(nvl(tot_caca.num_caca,1),1,0,imposta)) imposta_dett_anno,
                   sum(decode(nvl(tot_caca.num_caca,1),1,imposta,0)) imposta_anno,
                   count(*) numero,
                   f_descrizione_titr(:p_tipo_tributo,:p_anno) des_titr 
              from oggetti_imposta ogim    
                  ,oggetti_pratica ogpr    
                  ,oggetti ogge    
                  ,pratiche_tributo prtr 
                  ,(select count(distinct nvl(nvl(ogp2.categoria_catasto,ogg2.categoria_catasto),'!!')) num_caca
                          ,ogi2.aliquota
                      from oggetti_imposta ogi2    
                          ,oggetti_pratica ogp2    
                          ,oggetti ogg2    
                          ,pratiche_tributo prt2 
                     where prt2.pratica               = ogp2.pratica 
                       and ((prt2.tipo_pratica    in ('D','C')) or
                            (prt2.tipo_pratica     = 'A' and ogi2.anno > prt2.anno and prt2.flag_denuncia = 'S'))
                       and ogg2.oggetto             = ogp2.oggetto 
                       and ogp2.oggetto_pratica     = ogi2.oggetto_pratica 
                       and ogi2.flag_calcolo           = 'S' 
                       and prt2.tipo_tributo||''    = :p_tipo_tributo
                       and ogi2.anno               = :p_anno
                    group by ogi2.aliquota
                   ) tot_caca
              where prtr.pratica               = ogpr.pratica 
               and ((prtr.tipo_pratica    in ('D','C')) or
                    (prtr.tipo_pratica     = 'A' and ogim.anno > prtr.anno and prtr.flag_denuncia = 'S'))
               and ogge.oggetto            = ogpr.oggetto 
               and ogpr.oggetto_pratica    = ogim.oggetto_pratica 
               and ogim.flag_calcolo       = 'S' 
               and prtr.tipo_tributo||''   = :p_tipo_tributo
               and ogim.anno               = :p_anno
               and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) != 2
               and nvl(tot_caca.aliquota (+) ,-1)   = nvl(ogim.aliquota,-1)
             group by ogim.aliquota,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
              union all
            select '!!' ordinamento
                   ,'' categoria,
                   'AREE FABBRICABILI' des,
                   ogim.aliquota,
                   max(ogim.anno) anno,
                   sum(decode(nvl(tot_caca.num_caca,1),1,0,imposta)) imposta_dett_anno,
                   sum(decode(nvl(tot_caca.num_caca,1),1,imposta,0)) imposta_anno,
                   count(*) numero,
                   f_descrizione_titr(:p_tipo_tributo,:p_anno) des_titr 
              from oggetti_imposta ogim    
                  ,oggetti_pratica ogpr    
                  ,oggetti ogge    
                  ,pratiche_tributo prtr 
                  ,(select count(distinct nvl(nvl(ogp2.categoria_catasto,ogg2.categoria_catasto),'!')) num_caca
                          ,ogi2.aliquota
                      from oggetti_imposta ogi2    
                          ,oggetti_pratica ogp2    
                          ,oggetti ogg2    
                          ,pratiche_tributo prt2 
                     where prt2.pratica               = ogp2.pratica 
                       and ((prt2.tipo_pratica    in ('D','C')) or
                            (prt2.tipo_pratica     = 'A' and ogi2.anno > prt2.anno and prt2.flag_denuncia = 'S'))
                       and ogg2.oggetto             = ogp2.oggetto 
                       and ogp2.oggetto_pratica     = ogi2.oggetto_pratica 
                       and ogi2.flag_calcolo           = 'S' 
                       and prt2.tipo_tributo||''    = :p_tipo_tributo
                       and ogi2.anno               = :p_anno
                    group by ogi2.aliquota
                   ) tot_caca
              where prtr.pratica               = ogpr.pratica 
               and ((prtr.tipo_pratica    in ('D','C')) or
                    (prtr.tipo_pratica     = 'A' and ogim.anno > prtr.anno and prtr.flag_denuncia = 'S'))
               and ogge.oggetto            = ogpr.oggetto 
               and ogpr.oggetto_pratica    = ogim.oggetto_pratica 
               and ogim.flag_calcolo       = 'S' 
               and prtr.tipo_tributo||''   = :p_tipo_tributo
               and ogim.anno               = :p_anno
               and nvl(tot_caca.aliquota (+) ,-1)   = nvl(ogim.aliquota,-1)
               and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) = 2
               ${tributoWhere}
             group by ogim.aliquota
              union all
            select '!' ordinamento,
                   '',
                   decode(ogim.aliquota,null,'(Aliquote Multiple)','TOTALE ALIQUOTA '||translate(to_char(ogim.aliquota,'90.00'),'.',',')) des,
                   ogim.aliquota,
                   max(ogim.anno) anno,
                   0 imposta_dett_anno,
                   sum(imposta) imposta_anno
                   ,count(*) numero,
                   f_descrizione_titr(:p_tipo_tributo,:p_anno) des_titr 
              from oggetti_imposta ogim    
                  ,oggetti_pratica ogpr    
                  ,oggetti ogge    
                  ,pratiche_tributo prtr 
             where prtr.pratica               = ogpr.pratica 
               and ((prtr.tipo_pratica    in ('D','C')) or
                    (prtr.tipo_pratica     = 'A' and ogim.anno > prtr.anno and prtr.flag_denuncia = 'S'))
               and ogge.oggetto            = ogpr.oggetto 
               and ogpr.oggetto_pratica     = ogim.oggetto_pratica 
               and ogim.flag_calcolo           = 'S' 
               and prtr.tipo_tributo||''    = :p_tipo_tributo
               and ogim.anno               = :p_anno
             group by ogim.aliquota
            having count(distinct nvl(nvl(ogpr.categoria_catasto,ogge.categoria_catasto),'!')) > 0
             order by 4,1

                """

        def result = sessionFactory.currentSession.createSQLQuery(sql).with {

            param.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }.collect { row ->
            [
                    ordinamento     : row.ordinamento,
                    categoria       : row.categoria,
                    descrizione     : row.des,
                    aliquota        : row.aliquota,
                    anno            : row.anno,
                    impostaAnno     : row.impostaAnno,
                    impostaDettaglio: row.impostaDettAnno,
                    numero          : row.numero,
                    tributo         : row.desTitr,
                    campoOrdinamento: row.ordinamento
            ]
        }

        def listaTotaliAliquota = result.groupBy { it.aliquota }.collect { row ->

            def totale = row.value.find {
                it.descrizione.contains("TOTALE ALIQUOTA") || it.descrizione.contains("(Aliquote Multiple)")
            }

            if (totale) {
                row.value.remove(totale)
            }

            // La condizione sulla descrizione fa si che anche nel caso di 1 sola aliquota multipla, questa venga sempre riportata come dettaglio per maggior chiarezza
            if (row.value.size() > 1 || (totale && totale.descrizione == "(Aliquote Multiple)")) {

                totale.dettaglio = row.value
                return totale

            } else {
                row.value[0].dettaglio = []

                //I dettagli singoli trasformati in entry generali devono avere impostaAnno valorizzato e non impostaDettaglio
                if (row.value[0].impostaAnno == 0 && row.value[0].impostaDettaglio > 0) {
                    row.value[0].impostaAnno = row.value[0].impostaDettaglio
                    row.value[0].impostaDettaglio = 0
                }

                return row.value[0]
            }
        }

        return listaTotaliAliquota

    }

    def listaImpostePerTipologia(def anno, def tipoTributo, def tributo) {

        def lista = []
        def listaPaginata = []
        def totalCount = []

        def parametriQuery = [:]

        parametriQuery.pAnno = (short) anno
        parametriQuery.pTributo = tipoTributo

        String sql = """
		SELECT
			  ogim.anno AS anno
			, MAX(f_descrizione_titr(ogim.tipoTributo.tipoTributo, :pAnno)) AS des_titr
			, SUM( COALESCE(ogim.imposta, 0) ) AS imposta_anno
			, SUM( COALESCE(ogim.impostaAcconto, 0) ) AS imposta_acc_anno
			, SUM( COALESCE(ogim.imposta, 0) - COALESCE(ogim.impostaAcconto, 0) ) AS imposta_sal_anno
			, SUM( COALESCE(ogim.detrazione, 0) ) AS detrazione
			, SUM( COALESCE(ogim.detrazioneAcconto, 0) ) AS acc_detrazione
			, SUM( COALESCE(ogim.detrazione, 0) - COALESCE(ogim.detrazioneAcconto, 0) ) AS sal_detrazione
			, SUM( DECODE( COALESCE(ogpr.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto), 1, COALESCE(ogim.imposta, 0), 0) ) AS imposta_terreni
			, SUM( DECODE( COALESCE(ogpr.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto), 1,	COALESCE(ogim.impostaAcconto, 0), 0) ) AS imposta_acc_terreni
			, SUM( DECODE( COALESCE(ogpr.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto), 1,	COALESCE(ogim.imposta,0) - COALESCE(ogim.impostaAcconto, 0), 0) ) AS imposta_sal_terreni
			, SUM( DECODE( COALESCE(ogpr.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto), 2, COALESCE(ogim.imposta, 0), 0) ) AS imposta_aree
			, SUM( DECODE( COALESCE(ogpr.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto), 2,	COALESCE(ogim.impostaAcconto, 0), 0) ) AS imposta_acc_aree
			, SUM( DECODE( COALESCE(ogpr.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto), 2, COALESCE(ogim.imposta,0) - COALESCE(ogim.impostaAcconto, 0), 0) ) AS imposta_sal_aree
			, SUM( DECODE( COALESCE(ogpr.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto), 1, 0, 2, 0, DECODE( SUBSTR( COALESCE(ogpr.categoriaCatasto.categoriaCatasto, ogge.categoriaCatasto.categoriaCatasto), 1, 1 ), 'A', DECODE (ogco.flagAbPrincipale, 'S', COALESCE(ogim.imposta, 0), DECODE(ogpr.anno, :pAnno, DECODE(ogim.detrazione, null, 0, COALESCE(ogim.imposta, 0) ), 0) ), 0) ) ) AS imposta_ap
			, SUM( DECODE( COALESCE(ogpr.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto), 1,	0, 2, 0, DECODE( SUBSTR( COALESCE(ogpr.categoriaCatasto.categoriaCatasto, ogge.categoriaCatasto.categoriaCatasto), 1, 1 ), 'A',	DECODE (ogco.flagAbPrincipale, 'S', COALESCE(ogim.impostaAcconto, 0), DECODE(ogpr.anno, :pAnno, DECODE(ogim.detrazione, null, 0, COALESCE(ogim.impostaAcconto, 0) ), 0) ), 0) ) ) AS imposta_acc_ap
			, SUM( DECODE( COALESCE(ogpr.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto), 1,	0, 2, 0, DECODE( SUBSTR( COALESCE(ogpr.categoriaCatasto.categoriaCatasto, ogge.categoriaCatasto.categoriaCatasto), 1, 1 ), 'A', DECODE (ogco.flagAbPrincipale, 'S', COALESCE(ogim.imposta, 0) - COALESCE(ogim.impostaAcconto, 0), DECODE(ogpr.anno, :pAnno, DECODE(ogim.detrazione, null, 0, COALESCE(ogim.imposta, 0) - COALESCE(ogim.impostaAcconto,0) ), 0 ) ), 0) ) ) AS imposta_sal_ap
			, SUM( DECODE( COALESCE(ogpr.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto), 1, 0, 2, 0, DECODE( SUBSTR( COALESCE(ogpr.categoriaCatasto.categoriaCatasto, ogge.categoriaCatasto.categoriaCatasto), 1, 1 ), 'A', DECODE (ogco.flagAbPrincipale, 'S', 0, DECODE(ogpr.anno, :pAnno, DECODE(ogim.detrazione, null, COALESCE(ogim.imposta, 0), 0), COALESCE(ogim.imposta, 0) ) ), COALESCE(ogim.imposta,0) ) ) ) AS imposta_altri
			, SUM( DECODE( COALESCE(ogpr.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto), 1,	0, 2, 0, DECODE( SUBSTR( COALESCE(ogpr.categoriaCatasto.categoriaCatasto, ogge.categoriaCatasto.categoriaCatasto), 1, 1 ), 'A', DECODE (ogco.flagAbPrincipale, 'S', 0, DECODE(ogpr.anno, :pAnno, DECODE(ogim.detrazione, null, COALESCE(ogim.impostaAcconto, 0), 0), COALESCE(ogim.impostaAcconto, 0) ) ), COALESCE(ogim.impostaAcconto, 0) ) ) ) AS imposta_acc_altri
			, SUM( DECODE( COALESCE(ogpr.tipoOggetto.tipoOggetto, ogge.tipoOggetto.tipoOggetto), 1,	0, 2, 0, DECODE( SUBSTR( COALESCE(ogpr.categoriaCatasto.categoriaCatasto, ogge.categoriaCatasto.categoriaCatasto), 1, 1 ), 'A',	DECODE (ogco.flagAbPrincipale, 'S', 0, DECODE(ogpr.anno, :pAnno, DECODE(ogim.detrazione, null, COALESCE(ogim.imposta, 0) - COALESCE(ogim.impostaAcconto, 0), 0 ), COALESCE(ogim.imposta, 0) - COALESCE(ogim.impostaAcconto, 0) ) ), COALESCE(ogim.imposta,0) - COALESCE(ogim.impostaAcconto,0) ) ) ) AS imposta_sal_altri
		FROM
			OggettoPratica AS ogpr          
			INNER JOIN ogpr.pratica AS prtr          
			INNER JOIN ogpr.oggetto AS ogge          
			INNER JOIN ogpr.oggettiContribuente AS ogco         
			INNER JOIN ogco.oggettiImposta AS ogim          
		WHERE
			ogim.flagCalcolo ='S'          
			AND (
				prtr.tipoPratica IN ('D','C')         
				OR (
						prtr.tipoPratica = 'A'         
					AND ogim.anno > prtr.anno         
					AND prtr.flagDenuncia = 'S'
				)
			)         
			AND ogim.anno = :pAnno 
			AND ogim.tipoTributo.tipoTributo in (:pTributo)
		"""

        if (tributo) {
            sql += """
			AND ogpr.codiceTributo.id = ${tributo}
		"""
        }

        sql += """           
			GROUP BY
				ogim.anno
		"""

        lista = OggettoPratica.executeQuery(sql, parametriQuery).collect { row ->
            [anno                            : row[0]
             , tributo                       : row[1]
             , impostaAnno                   : new BigDecimal((row[2] == null) ? 0.00 : row[2])
             , impostaAccontoAnno            : new BigDecimal((row[3] == null) ? 0.00 : row[3])
             , impostaSaldoAnno              : new BigDecimal((row[4] == null) ? 0.00 : row[4])
             , detrazioneAnno                : new BigDecimal((row[5] == null) ? 0.00 : row[5])
             , detrazioneAccontoAnno         : new BigDecimal((row[6] == null) ? 0.00 : row[6])
             , detrazioneSaldoAnno           : new BigDecimal((row[7] == null) ? 0.00 : row[7])
             , impostaTerreniAnno            : new BigDecimal((row[8] == null) ? 0.00 : row[8])
             , impostaAccontoTerreniAnno     : new BigDecimal((row[9] == null) ? 0.00 : row[9])
             , impostaSaldoTerreniAnno       : new BigDecimal((row[10] == null) ? 0.00 : row[10])
             , impostaAreeAnno               : new BigDecimal((row[11] == null) ? 0.00 : row[11])
             , impostaAccontoAreeAnno        : new BigDecimal((row[12] == null) ? 0.00 : row[12])
             , impostaSaldoAreeAnno          : new BigDecimal((row[13] == null) ? 0.00 : row[13])
             , impostaAbPrincipaleAnno       : new BigDecimal((row[14] == null) ? 0.00 : row[14])
             , impostaAccontoAbPrincipaleAnno: new BigDecimal((row[15] == null) ? 0.00 : row[15])
             , impostaSaldoAbPrincipaleAnno  : new BigDecimal((row[16] == null) ? 0.00 : row[16])
             , impostaAltriAnno              : new BigDecimal((row[17] == null) ? 0.00 : row[17])
             , impostaAccontoAltriAnno       : new BigDecimal((row[18] == null) ? 0.00 : row[18])
             , impostaSaldoAltriAnno         : new BigDecimal((row[19] == null) ? 0.00 : row[19])
            ]
        }

        //return [total: lista.size(), result: lista]
        return lista
    }

    def getValore(
            def pAnno,
            def pValore,
            def pTipoOggetto,
            def pOggeTipoOggetto,
            def pOgcoAnno,
            def pRiogCategoriaCatasto,
            def pCategoriaCatasto, def pOggeCategoriaCatasto, def pPrtrTipoPratica, def pFlagValoreRivalutato) {

        def tipoOggetto = pTipoOggetto ?: pOggeTipoOggetto
        def categoriaCatasto = pRiogCategoriaCatasto ?: (pCategoriaCatasto ?: pOggeCategoriaCatasto)

        BigDecimal r

        // Connection conn = DataSourceUtils.getConnection(dataSource)
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_valore(?, ?, ?, ?, ?, ?, ?)}'
                , [Sql.DECIMAL, pValore, tipoOggetto, pOgcoAnno, pAnno, categoriaCatasto, pPrtrTipoPratica, pFlagValoreRivalutato ? "S" : "N"]) {
            r = it
        }

        return (r == null) ? 0 : r
    }

    def getValoreDaRendita(
            def pAnno,
            def pRendita,
            def pTipoOggetto,
            def pOggeTipoOggetto,
            def pRiogCategoriaCatasto, def pCategoriaCatasto, def pOggeCategoriaCatasto, def pImmStorico) {
        def tipoOggetto = pTipoOggetto ?: pOggeTipoOggetto
        def categoriaCatasto = pRiogCategoriaCatasto ?: (pCategoriaCatasto ?: pOggeCategoriaCatasto)

        BigDecimal r

        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_valore_da_rendita(?, ?, ?, ?, ?)}'
                , [Sql.DECIMAL, pRendita, tipoOggetto, pAnno, categoriaCatasto, pImmStorico ? "S" : "N"]) { r = it }

        return (r == null) ? 0 : r
    }

    def getDescrizioneCaca(def pCategoriaCatasto, def pOggeCategoriaCatasto) {

        def categoriaCatasto
        if (pCategoriaCatasto != null) {
            categoriaCatasto = pCategoriaCatasto?.categoriaCatasto
        } else {
            categoriaCatasto = pOggeCategoriaCatasto?.categoriaCatasto
        }

        def r

        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_descrizione_caca(?)}'
                , [Sql.VARCHAR, categoriaCatasto]) { r = it }

        if (r != null) {
            return r
        } else {
            return "IMMOBILI - CATEGORIA ASSENTE"
        }

    }

    def getDescrizioneTitr(def pAnno, def pTipoAttributo) {

        def r

        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_descrizione_titr(?, ?)}'
                , [Sql.VARCHAR, pTipoAttributo, pAnno]) { r = it }

        return r
    }

    def paginazioneLista(def lista, int pageSize, int activePage) {
        def listaPaginata = []

        // CALCOLO LA PAGINAZIONE
        def startRow = 0
        def totalPage
        def endRow

        // calcolo riga inizio pagina
        if (activePage == 0) {
            startRow = 0
        } else {
            startRow = ((int) pageSize * (int) activePage)
        }

        // calcolo riga FINE pagina
        endRow = ((int) pageSize * ((int) activePage + 1)) - 1

        if (endRow > (int) lista.size() - 1) {
            endRow = (int) lista.size() - 1
        }

        def conta = 0
        lista.each() { obj ->
            def contatore = conta++
            if (contatore >= startRow && contatore <= endRow) {
                listaPaginata += obj
            }
        }

        return listaPaginata
    }

    def getValoreImposta(def pAliquota, def pMappa) {
        def valore
        pMappa.each { m ->
            if (m.aliquota == pAliquota) {
                valore = m.categoria
            }
        }
        return valore
    }

    def getValoreImpostaAliquote(def pAliquota, def pMappa) {
        def valore
        pMappa.each { m ->
            if (m.aliquota == pAliquota) {
                valore = m.tipoAliquota
            }
        }
        return valore
    }

    @Transactional
    def proceduraCalcolaImposta(def anno, String codFiscale, String cognomeNome, String tipoTributo) {
        return proceduraCalcolaImposta(anno, codFiscale, cognomeNome, tipoTributo, null, 0, null, null, null)
    }

    @Transactional
    def proceduraCalcolaImposta(def anno, String codFiscale, String tipoTributo, String pFlagNormalizzato, Integer pChkRate, Double pLimite) {
        return proceduraCalcolaImposta(anno, codFiscale, tipoTributo, pFlagNormalizzato, pChkRate, pLimite, null)
    }


    @Transactional
    def proceduraCalcolaImposta(def anno, String codFiscale, String tipoTributo, String pFlagNormalizzato, Integer pChkRate, Double pLimite, def pPratica, def codiceElaborazione = null) {
        proceduraCalcolaImposta(anno, codFiscale, '%', tipoTributo, pFlagNormalizzato, pChkRate, pLimite, pPratica, codiceElaborazione)
    }

    @Transactional
    def proceduraCalcolaImposta(def anno, String codFiscale, String cognomeNome, String tipoTributo, String pFlagNormalizzato, Integer pChkRate, Double pLimite, 
																											def pPratica, def codiceElaborazione, def paramAggiuntivi = null) {

        String funzione
		String formatoParametri

		if(!paramAggiuntivi) {
			paramAggiuntivi = [:]
		}

        try {
            def pOgpr = null
            def pUtente = "TR4"
            def pFlagRichiamo = null
			def pFlagRavvedimento = null
			def allineamentoDePag = integrazioneDePagService.dePagAbilitato() && !(codFiscale ?: "%").contains("%")
			
            String result

            def oldCf = codFiscale

            codFiscale = codFiscale?.trim() ? "${codFiscale.toUpperCase()}" : '%'
            cognomeNome = cognomeNome?.trim() ? "${cognomeNome.toUpperCase()}" : '%'

            if (codFiscale == "%%") {
                codFiscale = "%"
            }

            if (cognomeNome == "%%") {
                cognomeNome = "%"
            }
			
            Sql sql = new Sql(dataSource)
			def params = []
			
			if(tipoTributo == 'CUNI') {
				funzione = "f_web_calcolo_imposta_cu"
				formatoParametri = '?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?'
				params = [
					Sql.VARCHAR,
					anno,
					codFiscale,
					tipoTributo,
					pOgpr,
					pUtente,
					pFlagNormalizzato == 'T' ? null : pFlagNormalizzato,
					pFlagRichiamo,
					pChkRate,
					pLimite,
					pPratica,
					pFlagRavvedimento,
					paramAggiuntivi?.gruppoTributo,
					paramAggiuntivi.scadenzaRata1 ? new java.sql.Date(paramAggiuntivi.scadenzaRata1.getTime()) : null,
					paramAggiuntivi.scadenzaRata2 ? new java.sql.Date(paramAggiuntivi.scadenzaRata2.getTime()) : null,
					paramAggiuntivi.scadenzaRata3 ? new java.sql.Date(paramAggiuntivi.scadenzaRata3.getTime()) : null,
					paramAggiuntivi.scadenzaRata4 ? new java.sql.Date(paramAggiuntivi.scadenzaRata4.getTime()) : null,
				]
			}
			else {
				funzione = "f_web_calcolo_imposta"
				formatoParametri = '?, ?, ?, ?, ?, ?, ?, ?, ?, ?'
				params = [
					Sql.VARCHAR,
					anno,
					codFiscale,
					tipoTributo,
					pOgpr,
					pUtente,
					pFlagNormalizzato == 'T' ? null : pFlagNormalizzato,
					pFlagRichiamo,
					pChkRate,
					pLimite,
					cognomeNome
				]
			}

            log.debug "Esecuzione ${funzione}"
            log.debug "Formato parametri ${formatoParametri}"
            log.debug "Con parametri ${params}"

			String callSQL = "{? = call ${funzione}(${formatoParametri})}"
            if (codiceElaborazione?.trim()) {
                tr4AfcElaborazioneService.saveDatabaseCall(codiceElaborazione, callSQL, params)
            }
            sql.call(callSQL, params) {
                result = it
            }

            if (allineamentoDePag) {
                /// Elimina i dovuti inoltrati al PT annullati dal calcolo
                integrazioneDePagService.eliminaDovutiAnnullatiSoggetto(oldCf, tipoTributo)
                /// Aggiorna ed allinea con il PT i nuovi dovuti
                integrazioneDePagService.aggiornaDovutoImposta(oldCf, anno, tipoTributo, null)
                if (pPratica) {
                    integrazioneDePagService.passaPraticaAPagoPA(pPratica, true)
                }
            }

            return result
        }
        catch (Exception e) {
            commonService.serviceException(e)
        }
    }

    @Transactional
    def proceduraCalcolaImpostaRavv(def idPratica) {

        def pratica = PraticaTributo.get(idPratica)

        try {
            def pUtente = "TR4"
            String r

            log.debug "Eliminazione delle sanzioni..."


            // Prima del caloclo imposta si devono rimuovere le sanzioni.
            def sanzioni = []

            pratica.sanzioniPratica.each {
                sanzioni << it
            }

            pratica.sanzioniPratica.clear()

            sanzioni.each {
                it.delete(flush: true)
            }

            log.debug "Sanzioni eliminate."

            log.debug "Esecuzione calcolo_imposta_${pratica.tipoTributo.tipoTributo}"
            Sql sql = new Sql(dataSource)
            sql.call("{call calcolo_imposta_${pratica.tipoTributo.tipoTributo}(?, ?, ?, ?)}"
                    , [pratica.anno, pratica.contribuente.codFiscale, 'TR4', 'S']) {
                r = it
            }
        } catch (Exception e) {
            commonService.serviceException(e)
        }
    }

    def getDovutoVersato(def filtro) {

        // Si effettua la copia del filtro per non riportare i valori di default su quello passato

        def filtroCopia = [:]
        filtro.each { k, v ->
            filtroCopia[k] = v
        }

        filtroCopia.dicDaAnno = filtroCopia.dicDaAnno ?: 0
        filtroCopia.diffImpDa = filtroCopia.diffImpDa ?: -9999999999999
        filtroCopia.diffImpA = filtroCopia.diffImpA ?: 9999999999999
        filtroCopia.tributo = filtroCopia.tributo ?: -1
        filtroCopia.codFiscale = filtroCopia.codFiscale?.toUpperCase() ?: '%'
        filtroCopia.cognomeNome = filtroCopia.cognomeNome?.toUpperCase() ?: '%'

        def lista = []
        def sqlCall = """
					DECLARE
						BEGIN
							? := f_web_dovuto_versato(?, ?, ?, ?, ?, ?, ?, ?, ?);
						END;
		"""

        Sql sql = new Sql(dataSource)
        sql.call(sqlCall,
                [
                        Sql.resultSet(OracleTypes.CURSOR),
                        //	a_titr         in varchar2
                        filtroCopia.tipoTributo.tipoTributo,
                        //	a_anno_rif     in number
                        filtroCopia.anno,
                        //	a_dic_da_anno  in number
                        filtroCopia.dicDaAnno,
                        //	a_tributo      in number
                        filtroCopia.tributo,
                        //	a_scf          in varchar2
                        filtroCopia.codFiscale,
                        //	a_snome        in varchar2
                        filtroCopia.cognomeNome,
                        //	a_tipo_imposta in number
                        filtroCopia.tipoDiffImp,
                        //	a_simp_da      number
                        filtroCopia.diffImpDa,
                        //	a_simp_a       number
                        filtroCopia.diffImpA
                ],
                { ResultSet rs ->
                    while (rs.next()) {

                        lista << [
                                codFiscale     : rs.getString("COD_FISCALE"),
                                ni             : rs.getInt("NI"),
                                tipoPersona    : rs.getInt("TIPO"),
                                versato        : rs.getBigDecimal("VERSATO"),
                                tardivo        : rs.getBigDecimal("TARDIVO"),
                                cognNom        : rs.getString("COGN_NOM"),
                                dovuto         : rs.getBigDecimal("DOVUTO"),
                                dovutoArr      : rs.getBigDecimal("DOVUTO_ARR"),
                                dovutoArrUte   : rs.getBigDecimal("DOVUTO_ARR_UTE"),
                                anno           : rs.getInt("ANNO"),
                                dataNasc       : rs.getDate("DATA_NASC"),
                                dicDaAnno      : rs.getInt("DIC_DA_ANNO"),
                                dicPrec        : rs.getString("DIC_PREC"),
                                liqCont        : rs.getString("LIQ_CONT"),
                                accCont        : rs.getString("ACC_CONT"),
                                cognome        : rs.getString("COGNOME"),
                                nome           : rs.getString("NOME"),
                                desTipoTributo : rs.getString("DES_TIPO_TRIBUTO"),
                                tipoTributo    : rs.getString("TIPO_TRIBUTO"),
                                descrizioneTitr: rs.getString("DESCR_TRIBUTO"),
                                occupante      : rs.getString("OCCUPANTE"),
                                proprietario   : rs.getString("PROPRIETARIO"),
                                statoSogg      : rs.getInt("STATO_SOGG"),
                                visibile       : true
                        ]
                    }
                }
        )

        return lista
    }

    def emissioneRuolo(def parametriCalcolo) {

        def r = Ruolo.get(parametriCalcolo.ruolo)
        r.flagIscrittiAltroRuolo = parametriCalcolo.flagIscrittiAltroRuolo ? 'S' : null
        r.save(failOnError: true, flush: true)

        Sql sql = new Sql(dataSource)

        Long ruoloId = parametriCalcolo.ruolo
        String codFiscale = parametriCalcolo.codFiscale
        String pUser = springSecurityService.currentUser.id

        if (parametriCalcolo.tipoCalcolo == 'T') {
            parametriCalcolo.flagTariffeRuolo = false
        }

        if (parametriCalcolo.tipoEmissione != 'A') {
            parametriCalcolo.percAcconto = 0
        }

        if (parametriCalcolo.ricalcolo) {

            def interessiDal = parametriCalcolo.ricalcoloDal ? new Date(parametriCalcolo.ricalcoloDal.getTime()) : null
            def interessiAl = parametriCalcolo.ricalcoloAl ? new Date(parametriCalcolo.ricalcoloAl.getTime()) : null

            sql.call('{ call CALCOLO_INTERESSI_RUOLO_S(?, ?, ?, ?, ?) }',
                    [
                            ruoloId,
                            pUser,
                            codFiscale,
                            interessiDal,
                            interessiAl
                    ]
            )
        }
        if (codFiscale == '%') {

            Ruolo ruolo = Ruolo.get(ruoloId)
            ruolo.tipoEmissione = parametriCalcolo.tipoEmissione
            ruolo.tipoCalcolo = parametriCalcolo.tipoCalcolo
            ruolo.percAcconto = parametriCalcolo.percAcconto ?: 0
            ruolo.flagTariffeRuolo = parametriCalcolo.flagTariffeRuolo ? 'S' : null
            ruolo.flagCalcoloTariffaBase = parametriCalcolo.flagCalcoloTariffaBase ? 'S' : null
            ruolo.flagDePag = parametriCalcolo.flagDePag ? 'S' : null
            ruolo.save(failOnError: true, flush: true)
        }

        String tipoCalcolo = (parametriCalcolo.tipoCalcolo != 'T') ? "'S'" : "null"
        String iscrittiAltroRuolo = (parametriCalcolo.iscrittiAltroRuolo) ? "'S'" : "null"

        String sqlCall = """
			DECLARE
				BEGIN
					EMISSIONE_RUOLO(${ruoloId}, '${pUser}', '${codFiscale}', 'PB', ${iscrittiAltroRuolo}, ${tipoCalcolo}, 
												'${parametriCalcolo.tipoLimite}', ${parametriCalcolo.limite ?: 0});
				END;
		"""

        sql.call(sqlCall)
    }

    def decorrenzaCessazione(def ruolo, def codFiscale = null) {

        String sql = """
			SELECT CONT.NI NI,
			       CONT.COD_FISCALE COD_FISCALE,
			       SOGG.COGNOME_NOME COGNOME_NOME,
			       OGVA.DAL DECORRENZA,
			       MIN(FASO.DAL) FAMILIARI_DAL,
			       OGVA.AL SCADENZA,
			       MAX(FASO.AL) FAMILIARI_AL,
			       OGCO.FLAG_AB_PRINCIPALE FLAG_AB_PRINCIPALE
			  FROM OGGETTI_VALIDITA     OGVA,
			       CONTRIBUENTI         CONT,
			       SOGGETTI             SOGG,
			       OGGETTI_PRATICA      OGPR,
			       OGGETTI_CONTRIBUENTE OGCO,
			       CATEGORIE            CATE,
			       FAMILIARI_SOGGETTO   FASO
			 WHERE CONT.COD_FISCALE = OGVA.COD_FISCALE
			 ${codFiscale != null ? " AND CONT.COD_FISCALE = :P_COD_FISCALE " : ""}
			   AND OGVA.TIPO_TRIBUTO || '' = 'TARSU'
			   AND CONT.NI = SOGG.NI
			   AND OGPR.OGGETTO_PRATICA = OGVA.OGGETTO_PRATICA
			   AND OGPR.CATEGORIA = CATE.CATEGORIA
			   AND OGPR.TRIBUTO = CATE.TRIBUTO
			   AND OGCO.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA
			   AND OGCO.FLAG_AB_PRINCIPALE IS NOT NULL
			   AND CATE.FLAG_DOMESTICA IS NOT NULL
			   AND FASO.NI = CONT.NI
			   AND FASO.ANNO = :P_ANNO
			   AND (DECODE(SIGN(NVL(TO_NUMBER(TO_CHAR(OGVA.DAL, 'yyyy')), :P_ANNO) -
			                    :P_ANNO),
			               -1,
			               TO_DATE('01/01/' || :P_ANNO, 'dd/mm/yyyy'),
			               OGVA.DAL) <
			       (SELECT MIN(FASO2.DAL)
			           FROM FAMILIARI_SOGGETTO FASO2
			          WHERE FASO2.NI = CONT.NI
			            AND FASO2.ANNO = :P_ANNO) OR
			       DECODE(SIGN(NVL(TO_NUMBER(TO_CHAR(OGVA.AL, 'yyyy')), :P_ANNO) -
			                    :P_ANNO),
			               1,
			               TO_DATE('31/12/' || :P_ANNO, 'dd/mm/yyyy'),
			               NVL(OGVA.AL, TO_DATE('31/12/' || :P_ANNO, 'dd/mm/yyyy'))) >
			       (SELECT MAX(NVL(FASO2.AL, TO_DATE('31/12/' || :P_ANNO, 'dd/mm/yyyy')))
			           FROM FAMILIARI_SOGGETTO FASO2
			          WHERE FASO2.NI = CONT.NI
			            AND FASO2.ANNO = :P_ANNO))
			   AND NVL(TO_NUMBER(TO_CHAR(OGVA.DAL, 'yyyy')), :P_ANNO) <= :P_ANNO
			   AND NVL(TO_NUMBER(TO_CHAR(OGVA.AL, 'yyyy')), :P_ANNO) >= :P_ANNO
			 GROUP BY CONT.NI,
			          CONT.COD_FISCALE,
			          SOGG.COGNOME_NOME,
			          OGVA.DAL,
			          OGVA.AL,
			          OGCO.FLAG_AB_PRINCIPALE
			 ORDER BY 2
			"""

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setLong('P_ANNO', ruolo.annoRuolo)

            if (codFiscale != null) {
                setString('P_COD_FISCALE', codFiscale)
            }

            list()
        }

        def records = []

        results.each {
            def record = [:]
            record.cognomeNome = it['COGNOME_NOME']
            record.familiariAl = it['FAMILIARI_AL']
            record.familiariDal = it['FAMILIARI_DAL']
            record.ni = it['NI']
            record.decorrenza = it['DECORRENZA']
            record.scadenza = it['SCADENZA']
            record.flagAbPri = it['FLAG_AB_PRINCIPALE']
            record.codFiscale = it['COD_FISCALE']

            records << record
        }

        return records
    }

    def eliminaImposta(def oggettoImpostaId) {

        def oggettoImposta = OggettoImposta.findById(oggettoImpostaId)

        if (oggettoImposta) {

            oggettoImposta.delete(flush: true, failOnError: true)
            return true
        }

        return false
    }

    def familiari(def ruolo, def codFiscale = null) {

        String sql = """
			SELECT CONT2.NI NI,
			       CONT2.COD_FISCALE COD_FISCALE,
			       SOGG2.COGNOME_NOME COGNOME_NOME,
			       MIN(OGVA2.DAL) DECORRENZA,
			       OGCO2.FLAG_AB_PRINCIPALE FLAG_AB_PRINCIPALE
			  FROM OGGETTI_VALIDITA     OGVA2,
			       CONTRIBUENTI         CONT2,
			       SOGGETTI             SOGG2,
			       OGGETTI_PRATICA      OGPR2,
			       OGGETTI_CONTRIBUENTE OGCO2,
			       CATEGORIE            CATE2
			 WHERE CONT2.COD_FISCALE = OGVA2.COD_FISCALE
			 ${codFiscale != null ? " AND CONT2.COD_FISCALE = :P_COD_FISCALE " : ""}
			   AND OGVA2.TIPO_TRIBUTO || '' = 'TARSU'
			   AND CONT2.NI = SOGG2.NI
			   AND OGPR2.OGGETTO_PRATICA = OGVA2.OGGETTO_PRATICA
			   AND OGPR2.CATEGORIA = CATE2.CATEGORIA
			   AND OGPR2.TRIBUTO = CATE2.TRIBUTO
			   AND OGCO2.OGGETTO_PRATICA = OGPR2.OGGETTO_PRATICA
			   AND OGCO2.FLAG_AB_PRINCIPALE IS NOT NULL
			   AND CATE2.FLAG_DOMESTICA IS NOT NULL
			   AND NOT EXISTS
			 (SELECT 'X'
			          FROM FAMILIARI_SOGGETTO FASO3
			         WHERE FASO3.NI = CONT2.NI
			           AND FASO3.ANNO = :P_ANNO)
			   AND NVL(TO_NUMBER(TO_CHAR(OGVA2.DAL, 'yyyy')), :P_ANNO) <= :P_ANNO
			   AND NVL(TO_NUMBER(TO_CHAR(OGVA2.AL, 'yyyy')), :P_ANNO) >= :P_ANNO
			 GROUP BY CONT2.NI,
			          CONT2.COD_FISCALE,
			          SOGG2.COGNOME_NOME,
			          OGCO2.FLAG_AB_PRINCIPALE
			 ORDER BY 2
		"""

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setLong('P_ANNO', ruolo.annoRuolo)

            if (codFiscale != null) {
                setString('P_COD_FISCALE', codFiscale)
            }

            list()
        }

        def records = []

        results.each {
            def record = [:]
            record.cognomeNome = it['COGNOME_NOME']
            record.ni = it['NI']
            record.codFiscale = it['COD_FISCALE']
            record.decorrenza = it['DECORRENZA']
            record.flagAbPri = it['FLAG_AB_PRINCIPALE']

            records << record
        }

        return records

    }

    def contribuentiNonResidentiConAbitazionePrincipale(def ruolo, def codFiscale = null) {

        String sql = """
			SELECT CONT.NI NI, 
			       CONT.COD_FISCALE COD_FISCALE, 
			       SOGG.COGNOME_NOME COGNOME_NOME, 
			       OGVA.DAL DECORRENZA, 
			       OGVA.AL CESSAZIONE, 
			       MIN(FASO.DAL) FAMILIARI_DAL, 
			       MAX(FASO3.DAL) FAMILIARI_AL, 
			       MAX(FASO3.NUMERO_FAMILIARI) NUMERO_FAMILIARI 
			  FROM OGGETTI_VALIDITA     OGVA, 
			       CONTRIBUENTI         CONT, 
			       SOGGETTI             SOGG, 
			       OGGETTI_PRATICA      OGPR, 
			       OGGETTI_CONTRIBUENTE OGCO, 
			       CATEGORIE            CATE, 
			       FAMILIARI_SOGGETTO   FASO, 
			       FAMILIARI_SOGGETTO   FASO3 
			 WHERE CONT.COD_FISCALE = OGVA.COD_FISCALE 
			 ${codFiscale != null ? " AND CONT.COD_FISCALE = :P_COD_FISCALE " : ""}
			   AND OGVA.TIPO_TRIBUTO || '' = 'TARSU' 
			   AND CONT.NI = SOGG.NI 
			   AND OGPR.OGGETTO_PRATICA = OGVA.OGGETTO_PRATICA 
			   AND OGPR.CATEGORIA = CATE.CATEGORIA 
			   AND OGPR.TRIBUTO = CATE.TRIBUTO 
			   AND OGCO.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA 
			   AND OGCO.FLAG_AB_PRINCIPALE = 'S' 
			   AND CATE.FLAG_DOMESTICA IS NOT NULL 
			   AND FASO.NI = CONT.NI 
			   AND FASO.ANNO = :P_ANNO 
			   AND FASO3.NI = CONT.NI 
			   AND FASO3.ANNO = :P_ANNO 
			   AND NVL(TO_NUMBER(TO_CHAR(OGVA.DAL, 'yyyy')), :P_ANNO) <= :P_ANNO 
			   AND NVL(TO_NUMBER(TO_CHAR(OGVA.AL, 'yyyy')), :P_ANNO) >= :P_ANNO 
			   AND SOGG.TIPO_RESIDENTE = 0 
			   AND SOGG.FASCIA NOT IN (1, 3) 
			 GROUP BY CONT.NI, CONT.COD_FISCALE, SOGG.COGNOME_NOME, OGVA.DAL, OGVA.AL 
			 ORDER BY 2
			"""
        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setLong('P_ANNO', ruolo.annoRuolo)

            if (codFiscale != null) {
                setString('P_COD_FISCALE', codFiscale)
            }

            list()
        }

        def records = []

        results.each {
            def record = [:]
            record.cognomeNome = it['COGNOME_NOME']
            record.familiariAl = it['FAMILIARI_AL']
            record.familiariDal = it['FAMILIARI_DAL']
            record.ni = it['NI']
            record.decorrenza = it['DECORRENZA']
            record.scadenza = it['CESSAZIONE']
            record.flagAbPri = it['NUMERO_FAMILIARI']
            record.codFiscale = it['COD_FISCALE']
            record.numeroFamiliari = it['NUMERO_FAMILIARI']


            records << record
        }
        return records
    }

    def contribuentiUtenzeDomesticheIncoerenti(short anno, long ruolo, String codFiscale) {
        String sql = """
						SELECT SOGG.NI,
			       CONT.COD_FISCALE,
			       SOGG.COGNOME_NOME,
			       CATE.TRIBUTO,
			       CATE.CATEGORIA,
			       'Mancano i coefficienti domestici x abitazione principale' as DESCRIZIONE
			  FROM (SELECT MAX(NUMERO_FAMILIARI) MAX_FAM
			          FROM COEFFICIENTI_DOMESTICI
			         WHERE ANNO = :P_ANNO) MAX_FAM,
			       FAMILIARI_SOGGETTO FASO,
			       PRATICHE_TRIBUTO PRTR,
			       OGGETTI_PRATICA OGPR,
			       OGGETTI_CONTRIBUENTE OGCO,
			       CATEGORIE CATE,
			       SOGGETTI SOGG,
			       CONTRIBUENTI CONT,
			       (SELECT RUOLO, DATA_EMISSIONE
			          FROM RUOLI
			         WHERE RUOLO = :P_RUOLO
			        UNION
			        SELECT :P_RUOLO, TRUNC(SYSDATE)
			          FROM DUAL
			         WHERE :P_RUOLO = -1) RUOL
			 WHERE FASO.NI = SOGG.NI
			   AND FASO.ANNO = :P_ANNO
			   AND SOGG.NI = CONT.NI
			   AND CATE.FLAG_DOMESTICA = 'S'
			   AND CATE.TRIBUTO = OGPR.TRIBUTO
			   AND CATE.CATEGORIA = OGPR.CATEGORIA
			   AND OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA
			   AND OGCO.COD_FISCALE = CONT.COD_FISCALE
			   AND RUOL.RUOLO = :P_RUOLO
			   AND PRTR.PRATICA = OGPR.PRATICA
			   AND (PRTR.TIPO_PRATICA = 'D' OR
			       PRTR.TIPO_PRATICA = 'A' AND PRTR.FLAG_ADESIONE = 'S' AND
			       PRTR.DATA_NOTIFICA IS NOT NULL OR
			       PRTR.TIPO_PRATICA = 'A' AND PRTR.FLAG_ADESIONE IS NULL AND
			       RUOL.DATA_EMISSIONE - PRTR.DATA_NOTIFICA > 60)
			   AND CONT.COD_FISCALE LIKE :P_CF
			   AND EXISTS
			 (SELECT 1
			          FROM OGGETTI_VALIDITA OGVA
			         WHERE NVL(TO_CHAR(OGVA.DAL, 'yyyy'), :P_ANNO) <= :P_ANNO
			           AND NVL(TO_CHAR(OGVA.AL, 'yyyy'), :P_ANNO) >= :P_ANNO
			           AND OGVA.COD_FISCALE = CONT.COD_FISCALE
			           AND OGVA.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA)
			   AND NOT EXISTS
			 (SELECT 1
			          FROM COEFFICIENTI_DOMESTICI
			         WHERE COEFFICIENTI_DOMESTICI.ANNO = FASO.ANNO
			           AND COEFFICIENTI_DOMESTICI.NUMERO_FAMILIARI =
			               DECODE(SIGN(FASO.NUMERO_FAMILIARI - MAX_FAM.MAX_FAM),
			                      1,
			                      MAX_FAM.MAX_FAM,
			                      FASO.NUMERO_FAMILIARI))
			   AND (OGCO.FLAG_AB_PRINCIPALE = 'S' OR
			       OGCO.FLAG_AB_PRINCIPALE IS NULL AND NOT EXISTS
			        (SELECT 1 FROM COMPONENTI_SUPERFICIE WHERE ANNO = :P_ANNO))
			UNION
			SELECT SOGG.NI,
			       CONT.COD_FISCALE,
			       SOGG.COGNOME_NOME,
			       CATE.TRIBUTO,
			       CATE.CATEGORIA,
			       'Mancano i coefficienti domestici x abitazione non principale'  as DESCRIZIONE
			  FROM (SELECT MAX(NUMERO_FAMILIARI) MAX_FAM
			          FROM COMPONENTI_SUPERFICIE
			         WHERE ANNO = :P_ANNO) MAX_FAM,
			       COMPONENTI_SUPERFICIE COSU,
			       PRATICHE_TRIBUTO PRTR,
			       OGGETTI_PRATICA OGPR,
			       OGGETTI_CONTRIBUENTE OGCO,
			       CATEGORIE CATE,
			       SOGGETTI SOGG,
			       CONTRIBUENTI CONT,
			       (SELECT RUOLO, DATA_EMISSIONE
			          FROM RUOLI
			         WHERE RUOLO = :P_RUOLO
			        UNION
			        SELECT :P_RUOLO, TRUNC(SYSDATE)
			          FROM DUAL
			         WHERE :P_RUOLO = -1) RUOL
			 WHERE COSU.ANNO = :P_ANNO
			   AND SOGG.NI = CONT.NI
			   AND CATE.FLAG_DOMESTICA = 'S'
			   AND CATE.TRIBUTO = OGPR.TRIBUTO
			   AND CATE.CATEGORIA = OGPR.CATEGORIA
			   AND OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA
			   AND OGCO.COD_FISCALE = CONT.COD_FISCALE
			   AND RUOL.RUOLO = :P_RUOLO
			   AND PRTR.PRATICA = OGPR.PRATICA
			   AND (PRTR.TIPO_PRATICA = 'D' OR
			       PRTR.TIPO_PRATICA = 'A' AND PRTR.FLAG_ADESIONE = 'S' AND
			       PRTR.DATA_NOTIFICA IS NOT NULL OR
			       PRTR.TIPO_PRATICA = 'A' AND PRTR.FLAG_ADESIONE IS NULL AND
			       RUOL.DATA_EMISSIONE - PRTR.DATA_NOTIFICA > 60)
			   AND CONT.COD_FISCALE LIKE :P_CF
			   AND EXISTS
			 (SELECT 1
			          FROM OGGETTI_VALIDITA OGVA
			         WHERE NVL(TO_CHAR(OGVA.DAL, 'yyyy'), :P_ANNO) <= :P_ANNO
			           AND NVL(TO_CHAR(OGVA.AL, 'yyyy'), :P_ANNO) >= :P_ANNO
			           AND OGVA.COD_FISCALE = CONT.COD_FISCALE
			           AND OGVA.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA)
			   AND NOT EXISTS
			 (SELECT 1
			          FROM COEFFICIENTI_DOMESTICI
			         WHERE COEFFICIENTI_DOMESTICI.ANNO = COSU.ANNO
			           AND COEFFICIENTI_DOMESTICI.NUMERO_FAMILIARI =
			               DECODE(SIGN(COSU.NUMERO_FAMILIARI - MAX_FAM.MAX_FAM),
			                      1,
			                      MAX_FAM.MAX_FAM,
			                      COSU.NUMERO_FAMILIARI))
			   AND OGCO.FLAG_AB_PRINCIPALE IS NULL
			   AND EXISTS
			 (SELECT 1 FROM COMPONENTI_SUPERFICIE WHERE ANNO = :P_ANNO)
			UNION
			SELECT SOGG.NI,
			       CONT.COD_FISCALE,
			       SOGG.COGNOME_NOME,
			       CATE.TRIBUTO,
			       CATE.CATEGORIA,
			       DECODE(OGCO.FLAG_AB_PRINCIPALE,
			              'S',
			              'I familiari indicati non coprono l''intero periodo di validità dell''oggetto',
			              'Mancano i componenti superficie')   as DESCRIZIONE
			  FROM CATEGORIE CATE,
			       OGGETTI_PRATICA OGPR,
			       PRATICHE_TRIBUTO PRTR,
			       OGGETTI_CONTRIBUENTE OGCO,
			       SOGGETTI SOGG,
			       CONTRIBUENTI CONT,
			       (SELECT RUOLO, DATA_EMISSIONE
			          FROM RUOLI
			         WHERE RUOLO = :P_RUOLO
			        UNION
			        SELECT :P_RUOLO, TRUNC(SYSDATE)
			          FROM DUAL
			         WHERE :P_RUOLO = -1) RUOL
			 WHERE CATE.TRIBUTO = OGPR.TRIBUTO
			   AND CATE.CATEGORIA = OGPR.CATEGORIA
			   AND CATE.FLAG_DOMESTICA = 'S'
			   AND SOGG.NI = CONT.NI
			   AND OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA
			   AND OGCO.COD_FISCALE = CONT.COD_FISCALE
			   AND CONT.COD_FISCALE LIKE :P_CF
			   AND RUOL.RUOLO = :P_RUOLO
			   AND PRTR.PRATICA = OGPR.PRATICA
			   AND (PRTR.TIPO_PRATICA = 'D' OR
			       PRTR.TIPO_PRATICA = 'A' AND PRTR.FLAG_ADESIONE = 'S' AND
			       PRTR.DATA_NOTIFICA IS NOT NULL OR
			       PRTR.TIPO_PRATICA = 'A' AND PRTR.FLAG_ADESIONE IS NULL AND
			       RUOL.DATA_EMISSIONE - PRTR.DATA_NOTIFICA > 60)
			   AND EXISTS
			 (SELECT 1
			          FROM OGGETTI_VALIDITA OGVA
			         WHERE NVL(TO_CHAR(OGVA.DAL, 'yyyy'), :P_ANNO) <= :P_ANNO
			           AND NVL(TO_CHAR(OGVA.AL, 'yyyy'), :P_ANNO) >= :P_ANNO
			           AND OGVA.COD_FISCALE = CONT.COD_FISCALE
			           AND OGVA.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA)
			   AND ((OGCO.FLAG_AB_PRINCIPALE = 'S' AND EXISTS
			        (SELECT 1
			            FROM OGGETTI_VALIDITA OGVA
			           WHERE NVL(TO_CHAR(OGVA.DAL, 'yyyy'), :P_ANNO) <= :P_ANNO
			             AND NVL(TO_CHAR(OGVA.AL, 'yyyy'), :P_ANNO) >= :P_ANNO
			             AND OGVA.COD_FISCALE = CONT.COD_FISCALE
			             AND OGVA.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA
			             AND F_TEST_COPERTURA_FASO(CONT.NI,
			                                       GREATEST(NVL(OGVA.DAL,
			                                                    TO_DATE('01/01/' || :P_ANNO,
			                                                            'dd/mm/yyyy')),
			                                                TO_DATE('01/01/' || :P_ANNO,
			                                                        'dd/mm/yyyy')),
			                                       LEAST(NVL(OGVA.AL,
			                                                 TO_DATE('31/12/' || :P_ANNO,
			                                                         'dd/mm/yyyy')),
			                                             TO_DATE('31/12/' || :P_ANNO,
			                                                     'dd/mm/yyyy')),:P_ANNO) = 'N')) OR
			       (OGCO.FLAG_AB_PRINCIPALE IS NULL AND NOT EXISTS
			        (SELECT 1 FROM COMPONENTI_SUPERFICIE WHERE ANNO = :P_ANNO)))
			 ORDER BY 3, 2
		"""

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setLong('P_RUOLO', ruolo)
            setLong('P_ANNO', anno)
            setString('P_CF', codFiscale)

            list()
        }

        def records = []

        results.each {
            def record = [:]
            record.ni = it['NI']
            record.codFiscale = it['COD_FISCALE']
            record.cognomeNome = it['COGNOME_NOME']
            record.tributo = it['TRIBUTO']
            record.categoria = it['CATEGORIA']
            record.descrizione = it['DESCRIZIONE']

            records << record
        }
        return records

    }

    def tariffeMancanti(def parametriCalcolo) {

        def ruolo = Ruolo.get(parametriCalcolo.ruolo)

        def result = commonService.refCursorToCollection("""F_TARIFFE_CHK('${ruolo.tipoTributo.tipoTributo}',
                                                      ${ruolo.annoRuolo},
                                                     '${parametriCalcolo.codFiscale}',
                                                     '${parametriCalcolo.tipoCalcolo}',
                                                      ${parametriCalcolo.flagCalcoloTariffaBase ? "'S'" : null},
                                                      ${parametriCalcolo.flagTariffeRuolo ? "'S'" : null}
                                                     )""")

        return result

    }

    def f24Ruolo(String codFiscale, Long ruolo, String stampaTrib = 'S', String stampaMagg = 'S', String ordinamento = 'C') {
        String sql = """
					select rate.rata ord2,
       contribuenti.cod_fiscale,
       translate(soggetti.cognome_nome, '/', ' ') csoggnome,
       decode(soggetti.cod_via,
              null,
              soggetti.denominazione_via,
              archivio_vie.denom_uff) ind,
       soggetti.num_civ num_civ,
       soggetti.suffisso suff,
       decode(soggetti.cod_via,
              null,
              soggetti.denominazione_via,
              archivio_vie.denom_uff) ||
       decode(soggetti.num_civ, null, '', ', ' || soggetti.num_civ) ||
       decode(soggetti.suffisso, null, '', '/' || soggetti.suffisso) indirizzo_dich,
       ad4_comuni_a.denominazione comune,
       ad4_provincie_a.sigla provincia,
       ad4_comuni_b.denominazione comune_nas,
       ad4_provincie_b.sigla provincia_nas,
       soggetti.sesso sesso,
       soggetti.cognome cognome,
       soggetti.nome nome,
       to_char(soggetti.data_nas, 'yyyy') anno_nascita,
       to_char(soggetti.data_nas, 'mm') mese_nascita,
       to_char(soggetti.data_nas, 'dd') giorno_nascita,
       to_char(ruol.anno_ruolo) anno,
       to_number(substr(f_f24_tares(1,
                                    decode(sign(rate.rata -
                                                tares.rate_versate),
                                           1,
                                           decode(rate.rata,
                                                  tares.rate,
                                                  importo_ultima_rata,
                                                  tares.importo_tares),
                                           0,
                                           decode(rate.rata,
                                                  tares.rate,
                                                  (tares.importo_tares *
                                                  (rate.rata - 1)) +
                                                  importo_ultima_rata,
                                                  (tares.importo_tares *
                                                  rate.rata)) -
                                           round(tares.versato),
                                           0),
                                    tares.num_fab_tares,
                                    tares.maggiorazione_tares,
                                    :p_se_stampa_trib,
                                    :p_se_stampa_magg,
                                    decode(rate.rata, tares.rate, 'S', '')),
                        5,
                        10)) importo_riga_1,
       to_number(substr(f_f24_tares(2,
                                    decode(sign(rate.rata -
                                                tares.rate_versate),
                                           1,
                                           decode(rate.rata,
                                                  tares.rate,
                                                  importo_ultima_rata,
                                                  tares.importo_tares),
                                           0,
                                           decode(rate.rata,
                                                  tares.rate,
                                                  (tares.importo_tares *
                                                  (rate.rata - 1)) +
                                                  importo_ultima_rata,
                                                  (tares.importo_tares *
                                                  rate.rata)) -
                                           round(tares.versato),
                                           0),
                                    tares.num_fab_tares,
                                    tares.maggiorazione_tares,
                                    :p_se_stampa_trib,
                                    :p_se_stampa_magg,
                                    decode(rate.rata, tares.rate, 'S', '')),
                        5,
                        10)) importo_riga_2,
       to_number(substr(f_f24_tares(3,
                                    decode(sign(rate.rata -
                                                tares.rate_versate),
                                           1,
                                           decode(rate.rata,
                                                  tares.rate,
                                                  importo_ultima_rata,
                                                  tares.importo_tares),
                                           0,
                                           decode(rate.rata,
                                                  tares.rate,
                                                  (tares.importo_tares *
                                                  (rate.rata - 1)) +
                                                  importo_ultima_rata,
                                                  (tares.importo_tares *
                                                  rate.rata)) -
                                           round(tares.versato),
                                           0),
                                    tares.num_fab_tares,
                                    tares.maggiorazione_tares,
                                    :p_se_stampa_trib,
                                    :p_se_stampa_magg,
                                    decode(rate.rata, tares.rate, 'S', '')),
                        5,
                        10)) importo_riga_3,
       substr(f_f24_tares(1,
                          decode(sign(rate.rata - tares.rate_versate),
                                 1,
                                 decode(rate.rata,
                                        tares.rate,
                                        importo_ultima_rata,
                                        tares.importo_tares),
                                 0,
                                 decode(rate.rata,
                                        tares.rate,
                                        (tares.importo_tares * (rate.rata - 1)) +
                                        importo_ultima_rata,
                                        (tares.importo_tares * rate.rata)) -
                                 round(tares.versato),
                                 0),
                          tares.num_fab_tares,
                          tares.maggiorazione_tares,
                          :p_se_stampa_trib,
                          :p_se_stampa_magg,
                          decode(rate.rata, tares.rate, 'S', '')),
              1,
              4) cotr_riga_1,
       substr(f_f24_tares(2,
                          decode(sign(rate.rata - tares.rate_versate),
                                 1,
                                 decode(rate.rata,
                                        tares.rate,
                                        importo_ultima_rata,
                                        tares.importo_tares),
                                 0,
                                 decode(rate.rata,
                                        tares.rate,
                                        (tares.importo_tares * (rate.rata - 1)) +
                                        importo_ultima_rata,
                                        (tares.importo_tares * rate.rata)) -
                                 round(tares.versato),
                                 0),
                          tares.num_fab_tares,
                          tares.maggiorazione_tares,
                          :p_se_stampa_trib,
                          :p_se_stampa_magg,
                          decode(rate.rata, tares.rate, 'S', '')),
              1,
              4) cotr_riga_2,
       substr(f_f24_tares(3,
                          decode(sign(rate.rata - tares.rate_versate),
                                 1,
                                 decode(rate.rata,
                                        tares.rate,
                                        importo_ultima_rata,
                                        tares.importo_tares),
                                 0,
                                 decode(rate.rata,
                                        tares.rate,
                                        (tares.importo_tares * (rate.rata - 1)) +
                                        importo_ultima_rata,
                                        (tares.importo_tares * rate.rata)) -
                                 round(tares.versato),
                                 0),
                          tares.num_fab_tares,
                          tares.maggiorazione_tares,
                          :p_se_stampa_trib,
                          :p_se_stampa_magg,
                          decode(rate.rata, tares.rate, 'S', '')),
              1,
              4) cotr_riga_3,
       substr(f_f24_tares(1,
                          decode(sign(rate.rata - tares.rate_versate),
                                 1,
                                 decode(rate.rata,
                                        tares.rate,
                                        importo_ultima_rata,
                                        tares.importo_tares),
                                 0,
                                 decode(rate.rata,
                                        tares.rate,
                                        (tares.importo_tares * (rate.rata - 1)) +
                                        importo_ultima_rata,
                                        (tares.importo_tares * rate.rata)) -
                                 round(tares.versato),
                                 0),
                          tares.num_fab_tares,
                          tares.maggiorazione_tares,
                          :p_se_stampa_trib,
                          :p_se_stampa_magg,
                          decode(rate.rata, tares.rate, 'S', '')),
              15,
              4) n_fab_riga_1,
       substr(f_f24_tares(2,
                          decode(sign(rate.rata - tares.rate_versate),
                                 1,
                                 decode(rate.rata,
                                        tares.rate,
                                        importo_ultima_rata,
                                        tares.importo_tares),
                                 0,
                                 decode(rate.rata,
                                        tares.rate,
                                        (tares.importo_tares * (rate.rata - 1)) +
                                        importo_ultima_rata,
                                        (tares.importo_tares * rate.rata)) -
                                 round(tares.versato),
                                 0),
                          tares.num_fab_tares,
                          tares.maggiorazione_tares,
                          :p_se_stampa_trib,
                          :p_se_stampa_magg,
                          decode(rate.rata, tares.rate, 'S', '')),
              15,
              4) n_fab_riga_2,
       substr(f_f24_tares(3,
                          decode(sign(rate.rata - tares.rate_versate),
                                 1,
                                 decode(rate.rata,
                                        tares.rate,
                                        importo_ultima_rata,
                                        tares.importo_tares),
                                 0,
                                 decode(rate.rata,
                                        tares.rate,
                                        (tares.importo_tares * (rate.rata - 1)) +
                                        importo_ultima_rata,
                                        (tares.importo_tares * rate.rata)) -
                                 round(tares.versato),
                                 0),
                          tares.num_fab_tares,
                          tares.maggiorazione_tares,
                          :p_se_stampa_trib,
                          :p_se_stampa_magg,
                          decode(rate.rata, tares.rate, 'S', '')),
              15,
              4) n_fab_riga_3,
       '' detr,
       '' acconto,
       '' saldo,
       ad4_comuni_c.sigla_cfis codice_comune,
       decode(to_number(to_char(sysdate, 'yyyy')),
              to_number(to_char(ruol.anno_ruolo, '9999')),
              '',
              'X') anno_imposta_diverso_solare,
       f_primo_erede_cod_fiscale(soggetti.ni) cod_fiscale_erede,
       '' ravvedimento,
       lpad(to_char(rate.rata
                    /*                       + decode (nvl (ruol.tipo_emissione, 'T')
                    ,'A', 0
                    ,'T', 0
                    ,ruol_prec.rate
                    ) */),
            2,
            '0') || lpad(to_char(tares.rate
                                 /*                       + decode (nvl (ruol.tipo_emissione, 'T')
                                 ,'A', 1
                                 ,'T', 0
                                 ,ruol_prec.rate
                                 ) */),
                         2,
                         '0') rateazione,
       ruol.rate,
       'RUOL' || to_char(ruol.anno_ruolo) ||
       lpad(to_char(rate.rata), 2, '0') ||
       lpad(to_char(ruol.ruolo), 8, '0') identificativo_operazione
  from ad4_comuni ad4_comuni_a,
       ad4_provincie ad4_provincie_a,
       archivio_vie,
       soggetti,
       contribuenti,
       ad4_comuni ad4_comuni_b,
       ad4_provincie ad4_provincie_b,
       dati_generali dage,
       ad4_comuni ad4_comuni_c,
       ruoli ruol,
       (select max(decode(ruol_prec.rate, 0, 1, null, 1, ruol_prec.rate)) rate
          from ruoli ruol_prec, ruoli ruol
         where nvl(ruol_prec.tipo_emissione(+), 'T') = 'A'
           and ruol_prec.invio_consorzio(+) is not null
           and ruol_prec.anno_ruolo(+) = ruol.anno_ruolo
           and ruol_prec.tipo_tributo(+) || '' = ruol.tipo_tributo
           and ruol.ruolo = :p_ruolo) ruol_prec,
       (select imco1.importo_rata importo_tares,
               imco1.versato,
               imco1.importo_tot,
               imco1.num_fab_tares,
               imco1.rate,
               imco1.ruolo,
               imco1.cod_fiscale,
               imco1.maggiorazione_tares,
               decode(imco1.importo_rata,
                      0,
                      0,
                      decode(sign(ceil(imco1.versato / imco1.importo_rata) -
                                  imco1.rate),
                             0,
                             imco1.rate,
                             1,
                             imco1.rate,
                             ceil(imco1.versato / imco1.importo_rata))) rate_versate,
               decode(imco1.importo_rata,
                      0,
                      imco1.importo_tot,
                      round(imco1.importo_tot -
                            ((imco1.importo_rata -
                            (imco1.versato -
                            (imco1.importo_rata *
                            decode(trunc(imco1.versato /
                                             imco1.importo_rata),
                                       ceil(imco1.versato / imco1.importo_rata),
                                       trunc(imco1.versato /
                                             imco1.importo_rata) - 1,
                                       trunc(imco1.versato /
                                             imco1.importo_rata))))) +
                            (imco1.importo_rata *
                            (imco1.rate -
                            ceil(imco1.versato / imco1.importo_rata) - 1))))) importo_ultima_rata
          from (select round((round((nvl(sum(ruog.importo), 0) -
                                    nvl(sum(ogim.maggiorazione_tares), 0)) +
                                    nvl(max(sanzioni.sanzione), 0) -
                                    f_tot_vers_cont_ruol(ruol.anno_ruolo,
                                                         ruog.cod_fiscale,
                                                         ruol.tipo_tributo,
                                                         ruog.ruolo,
                                                         'S') +
                                    f_tot_vers_cont_ruol(ruol.anno_ruolo,
                                                         ruog.cod_fiscale,
                                                         ruol.tipo_tributo,
                                                         ruog.ruolo,
                                                         'SM') -
                                    f_tot_vers_cont_ruol(ruol.anno_ruolo,
                                                         ruog.cod_fiscale,
                                                         ruol.tipo_tributo,
                                                         ruog.ruolo,
                                                         'C'),
                                    0)) /
                             decode(ruol.rate, null, 1, 0, 1, ruol.rate),
                             0) importo_rata,
                       decode(nvl(ruol.tipo_emissione, 'T'),
                              'T',
                              f_tot_vers_cont_ruol(ruol.anno_ruolo,
                                                   ruog.cod_fiscale,
                                                   ruol.tipo_tributo,
                                                   null,
                                                   'VN') +
                              decode(ruol.tipo_ruolo,
                                     2,
                                     round(f_imposta_evasa_acc(ruog.cod_fiscale,
                                                               'TARSU',
                                                               ruol.anno_ruolo,
                                                               'N'),
                                           0),
                                     0),
                              0) versato,
                       ((nvl(sum(ruog.importo), 0) -
                       nvl(sum(ogim.maggiorazione_tares), 0)) +
                       nvl(max(sanzioni.sanzione), 0) -
                       f_tot_vers_cont_ruol(ruol.anno_ruolo,
                                             ruog.cod_fiscale,
                                             ruol.tipo_tributo,
                                             ruog.ruolo,
                                             'S') +
                       f_tot_vers_cont_ruol(ruol.anno_ruolo,
                                             ruog.cod_fiscale,
                                             ruol.tipo_tributo,
                                             ruog.ruolo,
                                             'SM') -
                       f_tot_vers_cont_ruol(ruol.anno_ruolo,
                                             ruog.cod_fiscale,
                                             ruol.tipo_tributo,
                                             ruog.ruolo,
                                             'C') -
                       decode(nvl(ruol.tipo_emissione, 'T'),
                               'T',
                               f_tot_vers_cont_ruol(ruol.anno_ruolo,
                                                    ruog.cod_fiscale,
                                                    ruol.tipo_tributo,
                                                    null,
                                                    'VN') +
                               decode(ruol.tipo_ruolo,
                                      2,
                                      round(f_imposta_evasa_acc(ruog.cod_fiscale,
                                                                'TARSU',
                                                                ruol.anno_ruolo,
                                                                'N'),
                                            0),
                                      0),
                               0)) importo_tot,
                       greatest(0,
                                sum(ogim.maggiorazione_tares) -
                                decode(nvl(ruol.tipo_emissione, 'T'),
                                       'T',
                                       f_tot_vers_cont_ruol(ruol.anno_ruolo,
                                                            ruog.cod_fiscale,
                                                            ruol.tipo_tributo,
                                                            null,
                                                            'M') +
                                       decode(ruol.tipo_ruolo,
                                              2,
                                              round(f_imposta_evasa_acc(ruog.cod_fiscale,
                                                                        'TARSU',
                                                                        ruol.anno_ruolo,
                                                                        'S'),
                                                    0),
                                              0),
                                       0) -
                                f_tot_vers_cont_ruol(ruol.anno_ruolo,
                                                     ruog.cod_fiscale,
                                                     ruol.tipo_tributo,
                                                     ruog.ruolo,
                                                     'SM')) maggiorazione_tares,
                       count(1) num_fab_tares,
                       decode(ruol.rate, null, 1, 0, 1, ruol.rate) rate,
                       ruog.ruolo,
                       ruog.cod_fiscale
                  from oggetti_imposta    ogim,
                       ruoli_contribuente ruog,
                       ruoli              ruol,
                       sanzioni,
                       dati_generali      dage
                 where ruog.ruolo = ruol.ruolo
                   and ruog.oggetto_imposta = ogim.oggetto_imposta
                   and ruog.cod_fiscale = :p_cod_fiscale
                   and ruol.ruolo = :p_ruolo
                   and sanzioni.cod_sanzione(+) = 115
                   and sanzioni.tipo_tributo(+) = ruol.tipo_tributo
                   and nvl(:p_data_inizio, to_date('01/01/1900','dd/mm/yyyy')) 
                       between sanzioni.data_inizio and sanzioni.data_fine 
                 group by ruog.ruolo,
                          ruog.cod_fiscale,
                          ruol.rate,
                          ruol.tipo_emissione,
                          ruol.anno_ruolo,
                          ruol.tipo_tributo,
                          ruol.tipo_ruolo) imco1) tares,
       (select 1 rata
          from dual
        union all
        select 2 rata
          from dual
        union all
        select 3 rata
          from dual
        union all
        select 4 rata
          from dual
        union all
        select 5 rata
          from dual) rate
 where ad4_comuni_a.provincia_stato = ad4_provincie_a.provincia(+)
   and soggetti.cod_pro_res = ad4_comuni_a.provincia_stato(+)
   and soggetti.cod_com_res = ad4_comuni_a.comune(+)
   and soggetti.cod_via = archivio_vie.cod_via(+)
   and ad4_comuni_b.provincia_stato = ad4_provincie_b.provincia(+)
   and soggetti.cod_pro_nas = ad4_comuni_b.provincia_stato(+)
   and soggetti.cod_com_nas = ad4_comuni_b.comune(+)
   and soggetti.cod_via = archivio_vie.cod_via(+)
   and dage.pro_cliente = ad4_comuni_c.provincia_stato
   and dage.com_cliente = ad4_comuni_c.comune
   and contribuenti.ni = soggetti.ni
   and rate.rata <= tares.rate
   and contribuenti.cod_fiscale = :p_cod_fiscale
   and ruol.ruolo = :p_ruolo
   and tares.cod_fiscale = contribuenti.cod_fiscale
   and tares.ruolo = ruol.ruolo
   and (tares.importo_tot > 0.49 or
       nvl(tares.maggiorazione_tares, 0) > 0.49)
   and (decode(sign(rate.rata - tares.rate_versate),
               1,
               decode(rate.rata,
                      tares.rate,
                      importo_ultima_rata,
                      tares.importo_tares),
               0,
               decode(rate.rata,
                      tares.rate,
                      (tares.importo_tares * (rate.rata - 1)) +
                      importo_ultima_rata,
                      (tares.importo_tares * rate.rata)) -
               round(tares.versato),
               0) > 0 and nvl(:p_se_stampa_trib, ' ') = 'S' or
       (decode(rate.rata,
                tares.rate,
                decode(sign(rate.rata - tares.rate_versate),
                       1,
                       nvl(tares.maggiorazione_tares, 0),
                       0,
                       nvl(tares.maggiorazione_tares, 0),
                       nvl(tares.maggiorazione_tares, 0)),
                0) > 0 and nvl(:p_se_stampa_magg, ' ') = 'S'))
   and ruol.anno_ruolo < 2021
union all
select 99 ord2,
       contribuenti.cod_fiscale,
       translate(soggetti.cognome_nome, '/', ' ') csoggnome,
       decode(soggetti.cod_via,
              null,
              soggetti.denominazione_via,
              archivio_vie.denom_uff) ind,
       soggetti.num_civ num_civ,
       soggetti.suffisso suff,
       decode(soggetti.cod_via,
              null,
              soggetti.denominazione_via,
              archivio_vie.denom_uff) ||
       decode(soggetti.num_civ, null, '', ', ' || soggetti.num_civ) ||
       decode(soggetti.suffisso, null, '', '/' || soggetti.suffisso) indirizzo_dich,
       ad4_comuni_a.denominazione comune,
       ad4_provincie_a.sigla provincia,
       ad4_comuni_b.denominazione comune_nas,
       ad4_provincie_b.sigla provincia_nas,
       soggetti.sesso sesso,
       soggetti.cognome cognome,
       soggetti.nome nome,
       to_char(soggetti.data_nas, 'yyyy') anno_nascita,
       to_char(soggetti.data_nas, 'mm') mese_nascita,
       to_char(soggetti.data_nas, 'dd') giorno_nascita,
       to_char(ruol.anno_ruolo) anno,
       to_number(substr(f_f24_tares(1,
                                    tares.importo_tot,
                                    tares.num_fab_tares,
                                    tares.maggiorazione_tares,
                                    :p_se_stampa_trib,
                                    :p_se_stampa_magg,
                                    'S'),
                        5,
                        10)) importo_riga_1,
       to_number(substr(f_f24_tares(2,
                                    tares.importo_tot,
                                    tares.num_fab_tares,
                                    tares.maggiorazione_tares,
                                    :p_se_stampa_trib,
                                    :p_se_stampa_magg,
                                    'S'),
                        5,
                        10)) importo_riga_2,
       to_number(substr(f_f24_tares(3,
                                    tares.importo_tot,
                                    tares.num_fab_tares,
                                    tares.maggiorazione_tares,
                                    :p_se_stampa_trib,
                                    :p_se_stampa_magg,
                                    'S'),
                        5,
                        10)) importo_riga_3,
       substr(f_f24_tares(1,
                          tares.importo_tot,
                          tares.num_fab_tares,
                          tares.maggiorazione_tares,
                          :p_se_stampa_trib,
                          :p_se_stampa_magg,
                          'S'),
              1,
              4) cotr_riga_1,
       substr(f_f24_tares(2,
                          tares.importo_tot,
                          tares.num_fab_tares,
                          tares.maggiorazione_tares,
                          :p_se_stampa_trib,
                          :p_se_stampa_magg,
                          'S'),
              1,
              4) cotr_riga_2,
       substr(f_f24_tares(3,
                          tares.importo_tot,
                          tares.num_fab_tares,
                          tares.maggiorazione_tares,
                          :p_se_stampa_trib,
                          :p_se_stampa_magg,
                          'S'),
              1,
              4) cotr_riga_3,
       substr(f_f24_tares(1,
                          tares.importo_tot,
                          tares.num_fab_tares,
                          tares.maggiorazione_tares,
                          :p_se_stampa_trib,
                          :p_se_stampa_magg,
                          'S'),
              15,
              4) n_fab_riga_1,
       substr(f_f24_tares(2,
                          tares.importo_tot,
                          tares.num_fab_tares,
                          tares.maggiorazione_tares,
                          :p_se_stampa_trib,
                          :p_se_stampa_magg,
                          'S'),
              15,
              4) n_fab_riga_2,
       substr(f_f24_tares(3,
                          tares.importo_tot,
                          tares.num_fab_tares,
                          tares.maggiorazione_tares,
                          :p_se_stampa_trib,
                          :p_se_stampa_magg,
                          'S'),
              15,
              4) n_fab_riga_3,
       '' detr,
       '' acconto,
       '' saldo,
       ad4_comuni_c.sigla_cfis codice_comune,
       decode(to_number(to_char(sysdate, 'yyyy')),
              to_number(to_char(ruol.anno_ruolo, '9999')),
              '',
              'X') anno_imposta_diverso_solare,
       f_primo_erede_cod_fiscale(soggetti.ni) cod_fiscale_erede,
       '' ravvedimento,
       lpad(to_char(1
                    /*                      + decode (nvl (ruol.tipo_emissione, 'T')
                    ,'A', 0
                    ,'T', 0
                    ,ruol_prec.rate
                    ) */),
            2,
            '0') || lpad(to_char(1
                                 /*                       + decode (nvl (ruol.tipo_emissione, 'T')
                                 ,'A', 0
                                 ,'T', 0
                                 ,ruol_prec.rate
                                 ) */),
                         2,
                         '0') rateazione,
       ruol.rate,
       'RUOL' || to_char(ruol.anno_ruolo) || '00' ||
       lpad(to_char(ruol.ruolo), 8, '0') identificativo_operazione
  from ad4_comuni ad4_comuni_a,
       ad4_provincie ad4_provincie_a,
       archivio_vie,
       soggetti,
       contribuenti,
       ad4_comuni ad4_comuni_b,
       ad4_provincie ad4_provincie_b,
       dati_generali dage,
       ad4_comuni ad4_comuni_c,
       ruoli ruol,
       (select max(decode(ruol_prec.rate, 0, 1, null, 1, ruol_prec.rate)) rate
          from ruoli ruol_prec, ruoli ruol
         where nvl(ruol_prec.tipo_emissione(+), 'T') = 'A'
           and ruol_prec.invio_consorzio(+) is not null
           and ruol_prec.anno_ruolo(+) = ruol.anno_ruolo
           and ruol_prec.tipo_tributo(+) || '' = ruol.tipo_tributo
           and ruol.ruolo = :p_ruolo) ruol_prec,
       (select count(1) num_fab_tares,
               ((nvl(sum(ruog.importo), 0) -
               nvl(sum(ogim.maggiorazione_tares), 0)) +
               nvl(max(sanzioni.sanzione), 0) +
               decode(max(lpad(to_char(dage.pro_cliente), 3, '0') ||
                           lpad(to_char(dage.com_cliente), 3, '0')),
                       '049014',
                       nvl(sum(ogim.maggiorazione_tares), 0) -
                       nvl(round(sum(ogim.maggiorazione_tares), 0), 0),
                       0) - f_tot_vers_cont_ruol(ruol.anno_ruolo,
                                                  ruog.cod_fiscale,
                                                  ruol.tipo_tributo,
                                                  ruog.ruolo,
                                                  'S') -
               f_tot_vers_cont_ruol(ruol.anno_ruolo,
                                     ruog.cod_fiscale,
                                     ruol.tipo_tributo,
                                     ruog.ruolo,
                                     'C') -
               decode(nvl(ruol.tipo_emissione, 'T'),
                       'T',
                       f_tot_vers_cont_ruol(ruol.anno_ruolo,
                                            ruog.cod_fiscale,
                                            ruol.tipo_tributo,
                                            null,
                                            'VN') +
                       decode(ruol.tipo_ruolo,
                              2,
                              round(f_imposta_evasa_acc(ruog.cod_fiscale,
                                                        'TARSU',
                                                        ruol.anno_ruolo,
                                                        'N'),
                                    0),
                              0),
                       0)) importo_tot,
               ruog.ruolo,
               ruog.cod_fiscale,
               greatest(0,
                        nvl(sum(ogim.maggiorazione_tares), 0) -
                        decode(nvl(ruol.tipo_emissione, 'T'),
                               'T',
                               f_tot_vers_cont_ruol(ruol.anno_ruolo,
                                                    ruog.cod_fiscale,
                                                    ruol.tipo_tributo,
                                                    null,
                                                    'M') +
                               decode(ruol.tipo_ruolo,
                                      2,
                                      round(f_imposta_evasa_acc(ruog.cod_fiscale,
                                                                'TARSU',
                                                                ruol.anno_ruolo,
                                                                'S'),
                                            0),
                                      0),
                               0) - f_tot_vers_cont_ruol(ruol.anno_ruolo,
                                                         ruog.cod_fiscale,
                                                         ruol.tipo_tributo,
                                                         ruog.ruolo,
                                                         'SM')) maggiorazione_tares
          from oggetti_imposta    ogim,
               ruoli_contribuente ruog,
               sanzioni,
               ruoli              ruol,
               dati_generali      dage
         where ruog.ruolo = ruol.ruolo
           and ruog.oggetto_imposta = ogim.oggetto_imposta
           and sanzioni.cod_sanzione(+) = 115
           and sanzioni.tipo_tributo(+) = ruol.tipo_tributo
           and nvl(:p_data_inizio, to_date('01/01/1900','dd/mm/yyyy')) 
               between sanzioni.data_inizio and sanzioni.data_fine 
           and ruog.cod_fiscale = :p_cod_fiscale
           and ruol.ruolo = :p_ruolo
         group by ruog.ruolo,
                  ruog.cod_fiscale,
                  ruol.rate,
                  ruol.tipo_emissione,
                  ruol.anno_ruolo,
                  ruol.tipo_tributo,
                  ruol.tipo_ruolo) tares
 where ad4_comuni_a.provincia_stato = ad4_provincie_a.provincia(+)
   and soggetti.cod_pro_res = ad4_comuni_a.provincia_stato(+)
   and soggetti.cod_com_res = ad4_comuni_a.comune(+)
   and soggetti.cod_via = archivio_vie.cod_via(+)
   and ad4_comuni_b.provincia_stato = ad4_provincie_b.provincia(+)
   and soggetti.cod_pro_nas = ad4_comuni_b.provincia_stato(+)
   and soggetti.cod_com_nas = ad4_comuni_b.comune(+)
   and soggetti.cod_via = archivio_vie.cod_via(+)
   and dage.pro_cliente = ad4_comuni_c.provincia_stato
   and dage.com_cliente = ad4_comuni_c.comune
   and contribuenti.ni = soggetti.ni
   and contribuenti.cod_fiscale = :p_cod_fiscale
   and ruol.ruolo = :p_ruolo
   and tares.cod_fiscale = contribuenti.cod_fiscale
   and tares.ruolo = ruol.ruolo
   and f_f24_conta_righe_gdm(:p_se_stampa_trib,
                             :p_se_stampa_magg,
                             :p_cod_fiscale,
                             :p_ruolo) > 1
   and ruol.anno_ruolo < 2021
union
select rate.rata ord2,
       contribuenti.cod_fiscale,
       translate(soggetti.cognome_nome, '/', ' ') csoggnome,
       decode(soggetti.cod_via,
              null,
              soggetti.denominazione_via,
              archivio_vie.denom_uff) ind,
       soggetti.num_civ num_civ,
       soggetti.suffisso suff,
       decode(soggetti.cod_via,
              null,
              soggetti.denominazione_via,
              archivio_vie.denom_uff) ||
       decode(soggetti.num_civ, null, '', ', ' || soggetti.num_civ) ||
       decode(soggetti.suffisso, null, '', '/' || soggetti.suffisso) indirizzo_dich,
       ad4_comuni_a.denominazione comune,
       ad4_provincie_a.sigla provincia,
       ad4_comuni_b.denominazione comune_nas,
       ad4_provincie_b.sigla provincia_nas,
       soggetti.sesso sesso,
       soggetti.cognome cognome,
       soggetti.nome nome,
       to_char(soggetti.data_nas, 'yyyy') anno_nascita,
       to_char(soggetti.data_nas, 'mm') mese_nascita,
       to_char(soggetti.data_nas, 'dd') giorno_nascita,
       to_char(ruol.anno_ruolo) anno,
       to_number(substr(f_f24_tari_tefa(1,
                                        f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                             ruol.ruolo,
                                                             ruol.rate,
                                                             rate.rata,
                                                             'Q',
                                                             ''),
                                        tari.num_fab_tari,
                                        f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                             ruol.ruolo,
                                                             ruol.rate,
                                                             rate.rata,
                                                             'P',
                                                             '')),
                        5,
                        10)) importo_riga_1,
       to_number(substr(f_f24_tari_tefa(2,
                                        f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                             ruol.ruolo,
                                                             ruol.rate,
                                                             rate.rata,
                                                             'Q',
                                                             ''),
                                        tari.num_fab_tari,
                                        f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                             ruol.ruolo,
                                                             ruol.rate,
                                                             rate.rata,
                                                             'P',
                                                             '')),
                        5,
                        10)) importo_riga_2,
       to_number(substr(f_f24_tari_tefa(3,
                                        f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                             ruol.ruolo,
                                                             ruol.rate,
                                                             rate.rata,
                                                             'Q',
                                                             ''),
                                        tari.num_fab_tari,
                                        f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                             ruol.ruolo,
                                                             ruol.rate,
                                                             rate.rata,
                                                             'P',
                                                             '')),
                        5,
                        10)) importo_riga_3,
       substr(f_f24_tari_tefa(1,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   rate.rata,
                                                   'Q',
                                                   ''),
                              tari.num_fab_tari,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   rate.rata,
                                                   'P',
                                                   '')),
              1,
              4) cotr_riga_1,
       substr(f_f24_tari_tefa(2,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   rate.rata,
                                                   'Q',
                                                   ''),
                              tari.num_fab_tari,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   rate.rata,
                                                   'P',
                                                   '')),
              1,
              4) cotr_riga_2,
       substr(f_f24_tari_tefa(3,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   rate.rata,
                                                   'Q',
                                                   ''),
                              tari.num_fab_tari,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   rate.rata,
                                                   'P',
                                                   '')),
              1,
              4) cotr_riga_3,
       substr(f_f24_tari_tefa(1,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   rate.rata,
                                                   'Q',
                                                   ''),
                              tari.num_fab_tari,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   rate.rata,
                                                   'P',
                                                   '')),
              15,
              4) n_fab_riga_1,
       substr(f_f24_tari_tefa(2,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   rate.rata,
                                                   'Q',
                                                   ''),
                              tari.num_fab_tari,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   rate.rata,
                                                   'P',
                                                   '')),
              15,
              4) n_fab_riga_2,
       substr(f_f24_tari_tefa(3,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   rate.rata,
                                                   'Q',
                                                   ''),
                              tari.num_fab_tari,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   rate.rata,
                                                   'P',
                                                   '')),
              15,
              4) n_fab_riga_3,
       '' detr,
       '' acconto,
       '' saldo,
       ad4_comuni_c.sigla_cfis codice_comune,
       decode(to_number(to_char(sysdate, 'yyyy')),
              to_number(to_char(ruol.anno_ruolo, '9999')),
              '',
              'X') anno_imposta_diverso_solare,
       f_primo_erede_cod_fiscale(soggetti.ni) cod_fiscale_erede,
       '' ravvedimento,
       lpad(to_char(rate.rata +
                    decode(lpad(to_char(dage.pro_cliente), 3, '0') ||
                           lpad(to_char(dage.com_cliente), 3, '0'),
                           '017025',
                           decode(nvl(ruol.tipo_emissione, 'T'),
                                  'A',
                                  0,
                                  'T',
                                  0,
                                  ruol_prec.rate),
                           0)),
            2,
            '0') ||
       lpad(to_char(tari.rate +
                    decode(lpad(to_char(dage.pro_cliente), 3, '0') ||
                           lpad(to_char(dage.com_cliente), 3, '0'),
                           '017025',
                           decode(nvl(ruol.tipo_emissione, 'T'),
                                  'A',
                                  1,
                                  'T',
                                  0,
                                  ruol_prec.rate),
                           0)),
            2,
            '0') rateazione,
       ruol.rate,
       'RUOL' || to_char(ruol.anno_ruolo) ||
       lpad(to_char(rate.rata), 2, '0') ||
       lpad(to_char(ruol.ruolo), 8, '0') identificativo_operazione
  from ad4_comuni ad4_comuni_a,
       ad4_provincie ad4_provincie_a,
       archivio_vie,
       soggetti,
       contribuenti,
       ad4_comuni ad4_comuni_b,
       ad4_provincie ad4_provincie_b,
       dati_generali dage,
       ad4_comuni ad4_comuni_c,
       ruoli ruol,
       (select max(decode(ruol_prec.rate, 0, 1, null, 1, ruol_prec.rate)) rate
          from ruoli ruol_prec, ruoli ruol
         where nvl(ruol_prec.tipo_emissione(+), 'T') = 'A'
           and ruol_prec.invio_consorzio(+) is not null
           and ruol_prec.anno_ruolo(+) = ruol.anno_ruolo
           and ruol_prec.tipo_tributo(+) || '' = ruol.tipo_tributo
           and ruol.ruolo = :p_ruolo) ruol_prec,
       (select count(1) num_fab_tari,
               decode(ruol.rate, null, 1, 0, 1, ruol.rate) rate,
               ruog.ruolo,
               ruog.cod_fiscale
          from oggetti_imposta ogim, ruoli_contribuente ruog, ruoli ruol
         where ruog.ruolo = ruol.ruolo
           and ruog.oggetto_imposta = ogim.oggetto_imposta
           and ruog.cod_fiscale = :p_cod_fiscale
           and ruol.ruolo = :p_ruolo
         group by ruog.ruolo,
                  ruog.cod_fiscale,
                  ruol.rate,
                  ruol.tipo_emissione,
                  ruol.anno_ruolo,
                  ruol.tipo_tributo,
                  ruol.tipo_ruolo) tari,
       (select 1 rata
          from dual
        union all
        select 2 rata
          from dual
        union all
        select 3 rata
          from dual
        union all
        select 4 rata
          from dual
        union all
        select 5 rata
          from dual) rate
 where ad4_comuni_a.provincia_stato = ad4_provincie_a.provincia(+)
   and soggetti.cod_pro_res = ad4_comuni_a.provincia_stato(+)
   and soggetti.cod_com_res = ad4_comuni_a.comune(+)
   and soggetti.cod_via = archivio_vie.cod_via(+)
   and ad4_comuni_b.provincia_stato = ad4_provincie_b.provincia(+)
   and soggetti.cod_pro_nas = ad4_comuni_b.provincia_stato(+)
   and soggetti.cod_com_nas = ad4_comuni_b.comune(+)
   and soggetti.cod_via = archivio_vie.cod_via(+)
   and dage.pro_cliente = ad4_comuni_c.provincia_stato
   and dage.com_cliente = ad4_comuni_c.comune
   and contribuenti.ni = soggetti.ni
   and rate.rata <= tari.rate
   and contribuenti.cod_fiscale = :p_cod_fiscale
   and ruol.ruolo = :p_ruolo
   and tari.cod_fiscale = contribuenti.cod_fiscale
   and tari.ruolo = ruol.ruolo
   and (f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                             ruol.ruolo,
                             ruol.rate,
                             rate.rata,
                             'Q',
                             '') > 0 or
       f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                             ruol.ruolo,
                             ruol.rate,
                             rate.rata,
                             'P',
                             '') > 0)
   and ruol.anno_ruolo >= 2021
union all
select 99 ord2,
       contribuenti.cod_fiscale,
       translate(soggetti.cognome_nome, '/', ' ') csoggnome,
       decode(soggetti.cod_via,
              null,
              soggetti.denominazione_via,
              archivio_vie.denom_uff) ind,
       soggetti.num_civ num_civ,
       soggetti.suffisso suff,
       decode(soggetti.cod_via,
              null,
              soggetti.denominazione_via,
              archivio_vie.denom_uff) ||
       decode(soggetti.num_civ, null, '', ', ' || soggetti.num_civ) ||
       decode(soggetti.suffisso, null, '', '/' || soggetti.suffisso) indirizzo_dich,
       ad4_comuni_a.denominazione comune,
       ad4_provincie_a.sigla provincia,
       ad4_comuni_b.denominazione comune_nas,
       ad4_provincie_b.sigla provincia_nas,
       soggetti.sesso sesso,
       soggetti.cognome cognome,
       soggetti.nome nome,
       to_char(soggetti.data_nas, 'yyyy') anno_nascita,
       to_char(soggetti.data_nas, 'mm') mese_nascita,
       to_char(soggetti.data_nas, 'dd') giorno_nascita,
       to_char(ruol.anno_ruolo) anno,
       to_number(substr(f_f24_tari_tefa(1,
                                        f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                             ruol.ruolo,
                                                             ruol.rate,
                                                             0,
                                                             'Q',
                                                             ''),
                                        tari.num_fab_tari,
                                        f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                             ruol.ruolo,
                                                             ruol.rate,
                                                             0,
                                                             'P',
                                                             '')),
                        5,
                        10)) importo_riga_1,
       to_number(substr(f_f24_tari_tefa(2,
                                        f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                             ruol.ruolo,
                                                             ruol.rate,
                                                             0,
                                                             'Q',
                                                             ''),
                                        tari.num_fab_tari,
                                        f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                             ruol.ruolo,
                                                             ruol.rate,
                                                             0,
                                                             'P',
                                                             '')),
                        5,
                        10)) importo_riga_2,
       to_number(substr(f_f24_tari_tefa(3,
                                        f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                             ruol.ruolo,
                                                             ruol.rate,
                                                             0,
                                                             'Q',
                                                             ''),
                                        tari.num_fab_tari,
                                        f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                             ruol.ruolo,
                                                             ruol.rate,
                                                             0,
                                                             'P',
                                                             '')),
                        5,
                        10)) importo_riga_3,
       substr(f_f24_tari_tefa(1,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   0,
                                                   'Q',
                                                   ''),
                              tari.num_fab_tari,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   0,
                                                   'P',
                                                   '')),
              1,
              4) cotr_riga_1,
       substr(f_f24_tari_tefa(2,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   0,
                                                   'Q',
                                                   ''),
                              tari.num_fab_tari,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   0,
                                                   'P',
                                                   '')),
              1,
              4) cotr_riga_2,
       substr(f_f24_tari_tefa(3,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   0,
                                                   'Q',
                                                   ''),
                              tari.num_fab_tari,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   0,
                                                   'P',
                                                   '')),
              1,
              4) cotr_riga_3,
       substr(f_f24_tari_tefa(1,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   0,
                                                   'Q',
                                                   ''),
                              tari.num_fab_tari,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   0,
                                                   'P',
                                                   '')),
              15,
              4) n_fab_riga_1,
       substr(f_f24_tari_tefa(2,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   0,
                                                   'Q',
                                                   ''),
                              tari.num_fab_tari,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   0,
                                                   'P',
                                                   '')),
              15,
              4) n_fab_riga_2,
       substr(f_f24_tari_tefa(3,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   0,
                                                   'Q',
                                                   ''),
                              tari.num_fab_tari,
                              f_calcolo_rata_tarsu(contribuenti.cod_fiscale,
                                                   ruol.ruolo,
                                                   ruol.rate,
                                                   0,
                                                   'P',
                                                   '')),
              15,
              4) n_fab_riga_3,
       '' detr,
       '' acconto,
       '' saldo,
       ad4_comuni_c.sigla_cfis codice_comune,
       decode(to_number(to_char(sysdate, 'yyyy')),
              to_number(to_char(ruol.anno_ruolo, '9999')),
              '',
              'X') anno_imposta_diverso_solare,
       f_primo_erede_cod_fiscale(soggetti.ni) cod_fiscale_erede,
       '' ravvedimento,
       lpad(to_char(1 + decode(lpad(to_char(dage.pro_cliente), 3, '0') ||
                               lpad(to_char(dage.com_cliente), 3, '0'),
                               '017025',
                               decode(nvl(ruol.tipo_emissione, 'T'),
                                      'A',
                                      0,
                                      'T',
                                      0,
                                      ruol_prec.rate),
                               0)),
            2,
            '0') ||
       lpad(to_char(1 + decode(lpad(to_char(dage.pro_cliente), 3, '0') ||
                               lpad(to_char(dage.com_cliente), 3, '0'),
                               '017025',
                               decode(nvl(ruol.tipo_emissione, 'T'),
                                      'A',
                                      0,
                                      'T',
                                      0,
                                      ruol_prec.rate),
                               0)),
            2,
            '0') rateazione,
       ruol.rate,
       'RUOL' || to_char(ruol.anno_ruolo) || '00' ||
       lpad(to_char(ruol.ruolo), 8, '0') identificativo_operazione
  from ad4_comuni ad4_comuni_a,
       ad4_provincie ad4_provincie_a,
       archivio_vie,
       soggetti,
       contribuenti,
       ad4_comuni ad4_comuni_b,
       ad4_provincie ad4_provincie_b,
       dati_generali dage,
       ad4_comuni ad4_comuni_c,
       ruoli ruol,
       (select max(decode(ruol_prec.rate, 0, 1, null, 1, ruol_prec.rate)) rate
          from ruoli ruol_prec, ruoli ruol
         where nvl(ruol_prec.tipo_emissione(+), 'T') = 'A'
           and ruol_prec.invio_consorzio(+) is not null
           and ruol_prec.anno_ruolo(+) = ruol.anno_ruolo
           and ruol_prec.tipo_tributo(+) || '' = ruol.tipo_tributo
           and ruol.ruolo = :p_ruolo) ruol_prec,
       (select count(1) num_fab_tari, ruog.ruolo, ruog.cod_fiscale
          from oggetti_imposta    ogim,
               ruoli_contribuente ruog,
               ruoli              ruol,
               dati_generali      dage
         where ruog.ruolo = ruol.ruolo
           and ruog.oggetto_imposta = ogim.oggetto_imposta
           and ruog.cod_fiscale = :p_cod_fiscale
           and ruol.ruolo = :p_ruolo
         group by ruog.ruolo,
                  ruog.cod_fiscale,
                  ruol.rate,
                  ruol.tipo_emissione,
                  ruol.anno_ruolo,
                  ruol.tipo_tributo,
                  ruol.tipo_ruolo) tari
 where ad4_comuni_a.provincia_stato = ad4_provincie_a.provincia(+)
   and soggetti.cod_pro_res = ad4_comuni_a.provincia_stato(+)
   and soggetti.cod_com_res = ad4_comuni_a.comune(+)
   and soggetti.cod_via = archivio_vie.cod_via(+)
   and ad4_comuni_b.provincia_stato = ad4_provincie_b.provincia(+)
   and soggetti.cod_pro_nas = ad4_comuni_b.provincia_stato(+)
   and soggetti.cod_com_nas = ad4_comuni_b.comune(+)
   and soggetti.cod_via = archivio_vie.cod_via(+)
   and dage.pro_cliente = ad4_comuni_c.provincia_stato
   and dage.com_cliente = ad4_comuni_c.comune
   and contribuenti.ni = soggetti.ni
   and contribuenti.cod_fiscale = :p_cod_fiscale
   and ruol.ruolo = :p_ruolo
   and tari.cod_fiscale = contribuenti.cod_fiscale
   and tari.ruolo = ruol.ruolo
   and f_f24_conta_righe_gdm(:p_se_stampa_trib,
                             :p_se_stampa_magg,
                             :p_cod_fiscale,
                             :p_ruolo) > 1
   and ruol.anno_ruolo >= 2021
 order by 1
			"""

        def results = null

        def execTime = commonService.timeMe {
            results = sessionFactory.currentSession.createSQLQuery(sql).with {
                resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
                setString('p_cod_fiscale', codFiscale)
                setLong('p_ruolo', ruolo)
                setString('p_se_stampa_trib', stampaTrib)
                setString('p_se_stampa_magg', stampaMagg)
                setDate('p_data_inizio', null)
                // setString('p_ordinamento', ordinamento)

                list()
            }
        }
        log.info "[Esecuzione query F24] ${execTime}"

        def records = []

        results.each {
            def record = [:]
            it.each { k, v ->
                record[k] = v
                records << record
            }

            return records
        }
    }

    // Se si invoca da un Job si deve passare lo user:
    // springSecurityService?.currentUser è nullo
    def calcoloLiquidazioni(def parametriCalcolo, def user = null) {

        String tipoTributo = (parametriCalcolo.tributo == 'ICI') ? 'ICI' : 'TASI'

        String sqlWrk = "DELETE WRK_GENERALE WHERE UPPER(TIPO_TRATTAMENTO) = 'LIQUID. ${tipoTributo} ANNI'"

        if (parametriCalcolo.codiceElaborazione?.trim()) {
            tr4AfcElaborazioneService.saveDatabaseCall(parametriCalcolo.codiceElaborazione, sqlWrk)
        }

        sessionFactory.currentSession.createSQLQuery(sqlWrk).executeUpdate()

        parametriCalcolo.adAnno = parametriCalcolo.adAnno ?: parametriCalcolo.daAnno

        def risultato = 0

        for (int anno in parametriCalcolo.daAnno..parametriCalcolo.adAnno) {

            if (parametriCalcolo.flagRicalcoloDovuto) {
                proceduraCalcolaImposta(anno, parametriCalcolo.codFiscale, parametriCalcolo.cognomeNome, tipoTributo)
            }

            Sql sql = new Sql(dataSource)

            def stmt = "{call CALCOLO_LIQUIDAZIONI_${tipoTributo}(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}"
            def params = [anno,
                          parametriCalcolo.annoRiferimento,
                          parametriCalcolo.dataLiquidazione ? new Date(parametriCalcolo.dataLiquidazione.getTime()) : null,
                          parametriCalcolo.dataRifInteressi ? new Date(parametriCalcolo.dataRifInteressi.getTime()) : null,
                          parametriCalcolo.codFiscale.isEmpty() ? '%' : parametriCalcolo.codFiscale.toUpperCase(),
                          parametriCalcolo.cognomeNome.isEmpty() ? '%' : parametriCalcolo.cognomeNome.toUpperCase(),
                          parametriCalcolo.flagRiOg ? 'S' : null,
                          parametriCalcolo.daDataRiOg ? new Date(parametriCalcolo.daDataRiOg.getTime()) : null,
                          parametriCalcolo.aDataRiOg ? new Date(parametriCalcolo.aDataRiOg.getTime()) : null,
                          parametriCalcolo.daPercDiff,
                          parametriCalcolo.aPercDiff,
                          parametriCalcolo.limiteInf,
                          parametriCalcolo.limiteSup,
                          parametriCalcolo.flagRicalcolo ? 'S' : 'N',
                          springSecurityService?.currentUser?.id ?: user,
                          parametriCalcolo.flagVersamenti ? 'S' : 'N',
                          parametriCalcolo.flagRimborso ? 'S' : 'N',
                          parametriCalcolo.flagRavvedimento ? 'S' : 'N',
                          Sql.NUMERIC
            ]

            if (parametriCalcolo.codiceElaborazione?.trim()) {
                tr4AfcElaborazioneService.saveDatabaseCall(parametriCalcolo.codiceElaborazione, stmt, params)
            }

            sql.call(stmt, params, { res -> risultato += res })

            sqlWrk = "UPDATE WRK_GENERALE SET TIPO_TRATTAMENTO = 'LIQUID. ${tipoTributo} ANNI' WHERE UPPER(TIPO_TRATTAMENTO) = 'LIQUIDAZIONE ${tipoTributo}'"

            if (parametriCalcolo.codiceElaborazione?.trim()) {
                tr4AfcElaborazioneService.saveDatabaseCall(parametriCalcolo.codiceElaborazione, sqlWrk)
            }

            sessionFactory.currentSession.createSQLQuery(sqlWrk).executeUpdate()
        }

        return risultato
    }

    // Se si invoca da un Job si deve passare lo user:
    // springSecurityService?.currentUser è nullo
    def calcoloAccertamenti(def parametriCalcolo, def user = null) {

        try {
            Sql sql = new Sql(dataSource)
            String procedure
            String stmt
            def params = []

            String speseNotifica = parametriCalcolo.speseNotifica ? 'S' : null

            switch (parametriCalcolo.tributo) {
                case 'TARSU':
                    procedure = 'CALCOLO_ACC_AUTOMATICO_TARSU'
                    stmt = "{call $procedure(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}"
                    params = [
                            parametriCalcolo.tributo,
                            parametriCalcolo.anno,
                            parametriCalcolo.codFiscale?.trim()?.toUpperCase() ?: "%",
                            parametriCalcolo.cognomeNome?.trim()?.toUpperCase() ?: "%",
                            springSecurityService?.currentUser?.id ?: user,
                            parametriCalcolo.limiteInferiore,
                            parametriCalcolo.limiteSuperiore,
                            speseNotifica,
                            parametriCalcolo.dataInteressiDa ? new Date(parametriCalcolo.dataInteressiDa.time) : null,
                            parametriCalcolo.dataInteressiA ? new Date(parametriCalcolo.dataInteressiA.time) : null,
                            parametriCalcolo.tipoSollecitati ?: 'T',
                            parametriCalcolo.dataSollecitoDal ? new Date(parametriCalcolo.dataSollecitoDal.time) : null,
                            parametriCalcolo.dataSollecitoAl ? new Date(parametriCalcolo.dataSollecitoAl.time) : null,
                            parametriCalcolo.dataNotificaSolDal ? new Date(parametriCalcolo.dataNotificaSolDal.time) : null,
                            parametriCalcolo.dataNotificaSolAl ? new Date(parametriCalcolo.dataNotificaSolAl.time) : null,
                            Sql.NUMERIC
                    ]
                    break
                case ['ICP', 'TOSAP', 'CUNI']:
                    procedure = 'CALCOLO_ACC_AUTOMATICO'
                    stmt = "{call $procedure(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}"
                    params = [
                            parametriCalcolo.tributo,
                            parametriCalcolo.anno,
                            parametriCalcolo.codiceTributo,
                            parametriCalcolo.daCategoria,
                            parametriCalcolo.aCategoria,
                            parametriCalcolo.codFiscale.isEmpty() ? "%" : parametriCalcolo.codFiscale.toUpperCase(),
                            parametriCalcolo.cognomeNome.isEmpty() ? "%" : parametriCalcolo.cognomeNome.toUpperCase(),
                            springSecurityService?.currentUser?.id ?: user,
                            parametriCalcolo.limiteInferiore,
                            parametriCalcolo.limiteSuperiore,
                            speseNotifica,
                            parametriCalcolo.tipoSollecitati ?: 'T',
                            parametriCalcolo.dataSollecitoDal ? new Date(parametriCalcolo.dataSollecitoDal.time) : null,
                            parametriCalcolo.dataSollecitoAl ? new Date(parametriCalcolo.dataSollecitoAl.time) : null,
                            parametriCalcolo.dataNotificaSolDal ? new Date(parametriCalcolo.dataNotificaSolDal.time) : null,
                            parametriCalcolo.dataNotificaSolAl ? new Date(parametriCalcolo.dataNotificaSolAl.time) : null
                    ]
                    break
                default:
                    throw new Exception("Calcolo Accertamento non previsto per il tributo [${parametriCalcolo.tributo}]")
            }
            if (parametriCalcolo.codiceElaborazione?.trim()) {
                tr4AfcElaborazioneService.saveDatabaseCall(parametriCalcolo.codiceElaborazione, stmt, params)
            }

            Integer idPratica = null
            sql.call(stmt, params, parametriCalcolo.tributo == "TARSU" ?
                    { res ->
                        idPratica = res
                    } : {})

            return idPratica

        }
        catch (Exception e) {
            commonService.serviceException(e)
        }
    }

    // Se si invoca da un Job si deve passare lo user:
    // springSecurityService?.currentUser è nullo
    def calcoloSolleciti(def parametriCalcolo, def user = null) {

        Sql sql = new Sql(dataSource)
        Integer idPratica = null

        try {

            String speseNotifica = parametriCalcolo.speseNotifica ? 'S' : null

            switch (parametriCalcolo.tipoTributo) {
                case 'TARSU':
                    def statement = "{call CALCOLO_SOLLECITI_TARSU(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}"
                    def params = [
                            parametriCalcolo.tipoTributo,
                            parametriCalcolo.anno,
                            parametriCalcolo.codFiscale?.trim()?.toUpperCase() ?: "%",
                            parametriCalcolo.cognomeNome?.trim()?.toUpperCase() ?: "%",
                            parametriCalcolo.ruolo ?: 0,
                            parametriCalcolo.tributo ?: -1,
                            parametriCalcolo.limiteInferiore,
                            parametriCalcolo.limiteSuperiore,
                            speseNotifica,
                            new Date(parametriCalcolo.dataScadenza.getTime()),
                            springSecurityService?.currentUser?.id ?: user,
                            Sql.NUMERIC
                    ]
                    if (parametriCalcolo.codiceElaborazione?.trim()) {
                        tr4AfcElaborazioneService.saveDatabaseCall(parametriCalcolo.codiceElaborazione, statement, params)
                    }
                    sql.call(statement, params,
                            { res ->
                                idPratica = res
                            })
                    break
                case 'CUNI':
                    Short categoriaDa = 1
                    Short categoriaA = 9999
                    def statement = "{call CALCOLO_SOLLECITI(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}"
                    def params = [
                            parametriCalcolo.tipoTributo,
                            parametriCalcolo.anno,
                            parametriCalcolo.codFiscale?.trim()?.toUpperCase() ?: "%",
                            parametriCalcolo.cognomeNome?.trim()?.toUpperCase() ?: "%",
                            parametriCalcolo.tributo ?: -1,
                            parametriCalcolo.limiteInferiore,
                            parametriCalcolo.limiteSuperiore,
                            categoriaDa,
                            categoriaA,
                            speseNotifica,
                            new Date(parametriCalcolo.dataScadenza.getTime()),
                            springSecurityService?.currentUser?.id ?: user,
                            Sql.NUMERIC
                    ]
                    if (parametriCalcolo.codiceElaborazione?.trim()) {
                        tr4AfcElaborazioneService.saveDatabaseCall(parametriCalcolo.codiceElaborazione, statement, params)
                    }
                    sql.call(statement, params,
                            { res ->
                                idPratica = res
                            }
                    )
                    break
                default:
                    throw new Exception("Calcolo Solleciti non previsto per il tributo [${parametriCalcolo.tributo}]")
            }

        } catch (Exception e) {
            String message = ""
            if (e.message.startsWith("ORA-20999")) {
                message = e.message.substring('ORA-20999: '.length(), e.message.indexOf('ORA-06512')).trim()
                throw new Application20999Error(message)
            } else {
                throw e
            }
        }

        return idPratica
    }

    def contribuentiNonLiquidati(String tributo) {

        String sql = """
		         SELECT SUBSTR(WRK_GENERALE.PROGRESSIVO, 13, 3) PROGRESSIVO,
		               WRK_GENERALE.DATI COD_FIS,
		               TRANSLATE(SOGGETTI.COGNOME_NOME, '/', ' ') NOME,
		               WRK_GENERALE.ANNO ANNO,
		               SUBSTR(WRK_GENERALE.PROGRESSIVO, 7, 2) || '/' ||
		               SUBSTR(WRK_GENERALE.PROGRESSIVO, 5, 2) || '/' ||
		               SUBSTR(WRK_GENERALE.PROGRESSIVO, 1, 4) || ' ' ||
		               SUBSTR(WRK_GENERALE.PROGRESSIVO, 9, 2) || CHR(58) ||
		               SUBSTR(WRK_GENERALE.PROGRESSIVO, 11, 2) DATA,
						NVL(WRK_GENERALE.NOTE,'') AS NOTE_CALCOLO
		          FROM WRK_GENERALE, CONTRIBUENTI, SOGGETTI
		         WHERE (:p_tributo = 'ICI' AND WRK_GENERALE.TIPO_TRATTAMENTO IN
		               ('LIQUIDAZIONE ICI', 'LIQUID. ICI ANNI') OR
		               :p_tributo = 'TASI' AND
		               WRK_GENERALE.TIPO_TRATTAMENTO IN
		               ('LIQUIDAZIONE TASI', 'LIQUID. TASI ANNI'))
		           AND WRK_GENERALE.DATI = CONTRIBUENTI.COD_FISCALE
		           AND CONTRIBUENTI.NI = SOGGETTI.NI
			"""

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            setString('p_tributo', tributo)

            list()
        }

        def records = []

        results.each {

            def record = [:]

            it.each { k, v ->
                record[k] = v
                records << record
            }
            return records
        }
    }

    def inizializzaParametriCalcoloEmissioneRuolo(def ruolo, def codFiscale) {
        def parametriCalcolo = [:]

        ruolo = Ruolo.get(ruolo.id).toDTO()

        parametriCalcolo.ruolo = ruolo.id
        parametriCalcolo.codFiscale = codFiscale
        parametriCalcolo.tipoCalcolo = ruolo.tipoCalcolo ?: 'T'
        parametriCalcolo.tipoLimite = 'C'
        parametriCalcolo.limite = null
        parametriCalcolo.tipoEmissione = ruolo.tipoEmissione in ['A', 'S', 'T'] ? ruolo.tipoEmissione : 'T'
        parametriCalcolo.percAcconto = ruolo.percAcconto
        parametriCalcolo.flagTariffeRuolo = ruolo.flagTariffeRuolo == 'S'

        parametriCalcolo.flagCalcoloTariffaBase = (ruolo.flagCalcoloTariffaBase == 'S')

        parametriCalcolo.iscrittiAltroRuolo = false

        if (ruolo.tipoRuolo == TipoRuolo.PRINCIPALE.tipoRuolo) {
            if (ruolo.specieRuolo == SpecieRuolo.ORDINARIO.specieRuolo) {
                parametriCalcolo.iscrittiAltroRuolo = true
            }
        }
        parametriCalcolo.flagIscrittiAltroRuolo = (ruolo.flagIscrittiAltroRuolo == 'S')

        parametriCalcolo.ricalcolo = false
        parametriCalcolo.ricalcoloDal = null
        parametriCalcolo.ricalcoloAl = null
        parametriCalcolo.ricalcoloDisponibile = false
        if (ruolo.tipoRuolo == TipoRuolo.SUPPLETTIVO.tipoRuolo) {
            parametriCalcolo.ricalcoloDisponibile = true
        }

        parametriCalcolo.dePagAbilitato = integrazioneDePagService.dePagAbilitato()
        parametriCalcolo.flagDePag = (parametriCalcolo.dePagAbilitato) ? (ruolo.flagDePag == 'S') : false
        parametriCalcolo.flagDePagBloccato = parametriCalcolo.flagDePag

        return parametriCalcolo
    }

    def inserimentoARuolo(def ruolo, def codFiscale) {
        def messaggio = ""

        def parametriCalcolo = inizializzaParametriCalcoloEmissioneRuolo(ruolo, codFiscale)

        if (parametriCalcolo.tipoCalcolo == 'N') {
            contribuentiUtenzeDomesticheIncoerenti(ruolo.annoRuolo as short, ruolo.id as long, codFiscale).each {
                messaggio += "${it.descrizione}\n"
            }
        }

        // In presenza di errori non si procede con l'inserimento
        if (!messaggio.empty) {
            return messaggio
        }

        emissioneRuolo(parametriCalcolo)

        if (integrazioneDePagService.dePagAbilitato()) {
            messaggio = integrazioneDePagService.aggiornaDovutoRuolo(
                    codFiscale,
                    ruolo.id
            )
        }

        if (messaggio.replace("\n", "").trim().empty) {
            messaggio = ""
        }

        if (RuoloContribuente.findAllByRuoloAndContribuente(
                Ruolo.get(ruolo.id),
                Contribuente.findByCodFiscale(codFiscale))) {
            messaggio += "Contribuente inserito in ruolo ${ruolo.id}\n"
        } else {
            messaggio += "Contribuente non inserito in ruolo ${ruolo.id}\n"
        }

        return messaggio
    }

    // Esegue query
    private eseguiQuery(def query, def filtri, def paging, def wholeList = false) {

        filtri = filtri ?: [:]

        if (!query) {
            throw new RuntimeException("Query non specificata.")
        }

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(query)
        sqlQuery.with {

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            filtri.each { k, v ->
                setParameter(k, v)
            }

            if (!wholeList) {
                setFirstResult(paging.offset)
                setMaxResults(paging.max)
            }
            list()
        }
    }
}
