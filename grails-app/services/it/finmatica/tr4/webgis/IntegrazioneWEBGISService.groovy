package it.finmatica.tr4.webgis

import grails.transaction.Transactional
import grails.util.Holders
import groovy.xml.XmlUtil
import it.finmatica.ad4.dto.dizionari.Ad4ComuneDTO
import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.utility.AESCrypter
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.hibernate.transform.AliasToEntityMapResultTransformer
import org.zkoss.zhtml.Messagebox
import org.zkoss.zk.ui.util.Clients
import wslite.soap.SOAPClient

@Transactional(readOnly = true)
class IntegrazioneWEBGISService {

	private static Log log = LogFactory.getLog(IntegrazioneWEBGISService)

	DatiGeneraliService datiGeneraliService

	def dataSource

	def sessionFactory

	private codiceEnte = 'Z999'
	private codiceAccesso = ""
	private ticketAccesso = ""
	
	private final def ABILITAZIONE_MAPPE = "TRW_MAPPE"

	private final def INDIRIZZO_WEBAPI_SERVIZIO = "GIS_API"
	private final def INDIRIZZO_WEBGIS_SERVIZIO = "GIS_SERV"
	private final def INDIRIZZO_WEBGIS_URL = "GIS_WEB"

	private final def CRONOLOGIA_SINC_GIS = "GIS_CRON"
	private final def NUM_OGG_SINC_GIS = "GIS_NUM_OG"

	// Valori predefiniti per INSTALLAZIONE_PARAMETRI
	// ---------------------------------------------------------------------------------------------------------------------------------------------------------
	//	TRW_MAPPE	S															Visualizzazione Bottoni e Mappe nella TributiWeb
	//	GIS_API		https://maps.maxiportal.it/UrbeWebApi/ADS/ADS.asmx			Indirizzo completo del servizio ADS della WebAPI
	//	GIS_SERV	https://www.maxiportal.it/WEBGISDebug/ADS/ADS.asmx			Indirizzo completo del servizio ADS del WebGIS - Non parametrizzare qui !
	//	GIS_WEB		https://www.maxiportal.it/WEBGISDebug/Default.aspx			Indirizzo completo pagina predefinita del WebGIS
	//	GIS_CRON	0 0 22 ? * SAT *											Cronologia pianificazione Job sincronizzazione GIS
	//	GIS_NUM_OG	25															Numero massimo di oggetti elaborabili in un blocco

	//	GIS_CRON	0 0/10 * ? * * *											Valore per debug, ogni dieci minuti
	//	GIS_CRON	0 0 22 ? * * *												Valore per debug, alle 22 ogni giorno

	private def integrazioneGisAbilitata = null

	private def indirizzoWebAPIServizio = null
	private def indirizzoWebGISServizio = null
	private def indirizzoWebGISURL = null

	private def cronologiaSincroniaGIS = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == CRONOLOGIA_SINC_GIS }
	private def numOggettiSincroniaGIS = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == NUM_OGG_SINC_GIS }

	///
	/// *** Riporta true se integrazione abilitata a livello di DB
	///
	def integrazioneAbilitata() {

		this.integrazioneGisAbilitata = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == ABILITAZIONE_MAPPE }

		return this.integrazioneGisAbilitata?.valore in ['S', 'X']
	}

	///
	/// *** Riporta true se sincronizzazione abilitata a livello di DB
	///
	def sincronizzazioneAbilitata() {

		return this.integrazioneGisAbilitata?.valore in ['X']
	}

	///
	/// *** Rilegge impostazioni
	///
	def impostazioniRileggi() {

		this.indirizzoWebAPIServizio = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == INDIRIZZO_WEBAPI_SERVIZIO }
		this.indirizzoWebGISServizio = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == INDIRIZZO_WEBGIS_SERVIZIO }
		this.indirizzoWebGISURL = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == INDIRIZZO_WEBGIS_URL }

		this.numOggettiSincroniaGIS = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == NUM_OGG_SINC_GIS }
	}

	///
	/// *** Crea richiesta di visualizzazione oggetti su WebGIS partendo da elenco
	///
	def openWebGis(def oggetti) {

		if ((oggetti == null) || (oggetti.size() == 0)) {

			String title = "Problema di selezione"
			String message = "Attenzione :\n\nNessun oggetto in elenco"
			Messagebox.show(message, title, Messagebox.OK, Messagebox.ERROR)
			return
		}

		this.codiceEnte = codiceEnte()
		this.codiceAccesso = ''
		this.ticketAccesso = ''

		impostazioniRileggi()

		///
		/// *** Impostazioni per Test con WebGIS e API in locale
		///		Da eliminare in produzione !!!!!!!!!!
		///
		///	impostazioniPerDebug();
		///

		String urlWebGIS = this.indirizzoWebGISURL?.valore ?: ''
		urlWebGIS = parseUrl(urlWebGIS)

		String tipoRichiesta = "EvidenziaCatasto"
		String tokenWebGIS = addOggettiWebGIS(oggetti, tipoRichiesta)

		if (tokenWebGIS.indexOf("--") < 0) {

			String url
			
			if(this.ticketAccesso.size() > 0) {
				url = urlWebGIS + "?AUTHENTICATION=${this.ticketAccesso}"
				url = url + "&ID=${tokenWebGIS}"
			}
			else {
				url = urlWebGIS + "?CODCOM=${this.codiceEnte}"
				url = url + "&INT=ADS&ID=${tokenWebGIS}"
			}
			
			if (this.codiceAccesso.length() > 0) url = url + "&" + this.codiceAccesso

			Clients.evalJavaScript("window.open('${url}','_blank');")
		} else {

			String title = "Errore di comunizazione"
			String message = "Attenzione :\n\nSi e' verificato un errore di comunicazione con il WebGIS !\n\n" + tokenWebGIS + " !"
			Messagebox.show(message, title, Messagebox.OK, Messagebox.QUESTION)
		}
	}

	///
	/// *** Riporta Cron per servizio sincronizzazione GIS
	///
	String leggiWebGISCron() {

		String cronJob = cronologiaSincroniaGIS?.valore
		if (cronJob == null) cronJob = ""

		return cronJob
	}

	///
	/// *** Riporta dati per Batch
	///
	def leggiConfigurazioneBatch() {

		String utente = Holders.getGrailsApplication()?.config?.grails?.plugins?.afcquartz?.utenteBatch
		if (!utente) utente = "TR4"

		def filtri = [:]

		filtri << ['nomeUtente': utente]

		String sql = """
				SELECT
					COMP.OGGETTO ENTI
				FROM
					SI4_COMPETENZE COMP,
					SI4_ABILITAZIONI ABI,
					SI4_TIPI_ABILITAZIONE TIAB,
					SI4_TIPI_OGGETTO TOGG
				WHERE
					COMP.ID_ABILITAZIONE = ABI.ID_ABILITAZIONE AND
					TIAB.ID_TIPO_ABILITAZIONE = ABI.ID_TIPO_ABILITAZIONE AND
					TOGG.ID_TIPO_OGGETTO = ABI.ID_TIPO_OGGETTO AND
					TIAB.TIPO_ABILITAZIONE = 'AA' AND
					COMP.UTENTE = :nomeUtente
		"""

		String enti = ""

		def params = [:]
		params.max = 1
		params.activePage = 0
		params.offset = 0

		def results = eseguiQuery("${sql}", filtri, params, false)
		results.each {
			enti = it['ENTI']
		}
		if (!enti) enti = "FINMATICA"

		return [utente: utente, enti: enti]
	}

	///
	/// *** Elabora operazioni di sincronizzazione GIS
	///
	def sincronizzaWebGIS() {

		this.codiceEnte = codiceEnte()
		this.codiceAccesso = ''
		this.ticketAccesso = ''

		impostazioniRileggi()

		String resultMsg = "-- Tutto da fare --"
		String result

		String tipoRichiesta
		String attributiRichiesta

		log.info "SincronizzaWebGIS : Iniziato"

		String urlWebAPI = this.indirizzoWebAPIServizio?.valore ?: ''
		String urlAPI = parseUrl(urlWebAPI)

		int done = 0
		int skipped = 0

		int fatale = 0
		int errori = 0

		try {
			def elencoOperazioni = elencoOperazioniWebGIS()

			elencoOperazioni.each {

				log.info "Operazione : ${it}"

				if (it.disabilitato != 'S') {
					def elencoOggetti = elencoOggettiWebGIS(it.vista, it.filtro, true)
					def numeroOggetti = elencoOggetti.size()

					log.info "Oggetti : ${numeroOggetti}"

					switch (it.funzione) {
						default:
							tipoRichiesta = ""
							errori++
							break
						case "ImpostaEdificabile_No":
							tipoRichiesta = "ImpostaEdificabile"
							attributiRichiesta = "<flagEdificabile>0</flagEdificabile>"
							break
						case "ImpostaEdificabile_Si":
							tipoRichiesta = "ImpostaEdificabile"
							attributiRichiesta = "<flagEdificabile>1</flagEdificabile>"
							break
						case "ImpostaEdificabile_Bonifica":
							tipoRichiesta = "ImpostaEdificabile"
							attributiRichiesta = "<flagEdificabile>-1</flagEdificabile>"
							break
						case "ImpostaAccertato_No":
							tipoRichiesta = "ImpostaAccertato"
							attributiRichiesta = "<flagAccertato>0</flagAccertato>"
							break
						case "ImpostaAccertato_Si":
							tipoRichiesta = "ImpostaAccertato"
							attributiRichiesta = "<flagAccertato>1</flagAccertato>"
							break
						case "ImpostaAccertato_Irregolare":
							tipoRichiesta = "ImpostaAccertato"
							attributiRichiesta = "<flagAccertato>2</flagAccertato>"
							break
						case "ImpostaAccertato_NoDB":
							tipoRichiesta = "ImpostaAccertato"
							attributiRichiesta = "<flagAccertato>10</flagAccertato>"
							break
						case "ImpostaAccertato_Bonifica":
							tipoRichiesta = "ImpostaAccertato"
							attributiRichiesta = "<flagAccertato>-1</flagAccertato>"
							break
					}

					if (tipoRichiesta != "") {

						result = richiestaWebGIS(urlAPI, tipoRichiesta, attributiRichiesta, elencoOggetti)
						if (result.indexOf("--") >= 0)
							throw new Exception(result)
					}

					done++
				} else {
					skipped++
				}
			}
		}
		catch (Exception ex) {

			resultMsg = "Si e' verificato un errore : " + ex.toString()
			fatale++
		}

		if (fatale == 0) {

			resultMsg = "Operazioni eseguite / saltate / errori totali : ${done} / ${skipped} / ${errori}"
		}

		log.info "SincronizzaWebGIS : Finito -> ${resultMsg}"

		return resultMsg
	};

	/// ############################################################################################################################

	///
	/// *** Legge da DB elenco unificato immobili catastali
	///
	def listaCatasto(def listaFiltri, int pageSize = Integer.MAX_VALUE, int activePage = 0) {

		String sql = ""
		String sqlTotali = ""
		String sqlFiltri = ""
		String sqlElenco
		String sqlSingolo

		def filtri = [:]

		if (listaFiltri) {

			sqlElenco = ""

			listaFiltri.each {

				sqlSingolo = ""

				if (it.sezione) {
					if (sqlSingolo != "") sqlSingolo += " AND "
					sqlSingolo += "SEZIONE = '${it.sezione}'"
				}
				if (it.foglio) {
					if (sqlSingolo != "") sqlSingolo += " AND "
					sqlSingolo += "FOGLIO = '${it.foglio}'"
				}
				if (it.numero) {
					if (sqlSingolo != "") sqlSingolo += " AND "
					sqlSingolo += "NUMERO = '${it.numero}'"
				}
				if (it.subalterno) {
					if (sqlSingolo != "") sqlSingolo += " AND "
					sqlSingolo += "SUBALTERNO = '${it.subalterno}'"
				}
				if (sqlElenco != "") sqlElenco += " OR "
				sqlElenco += "(" + sqlSingolo + ")"
			}
			if (sqlElenco != "") {

				if (sqlFiltri != "") sqlFiltri += " AND "
				sqlFiltri += "("
				sqlFiltri += sqlElenco
				sqlFiltri += ")"
			}
		}
		if (sqlFiltri != "") sqlFiltri = "WHERE " + sqlFiltri

		sql = """
			SELECT * FROM
				(
				SELECT DISTINCT
					TO_NUMBER(IMM.CONTATORE) AS IDIMMOBILE,
					IMM.INDIRIZZO AS INDIRIZZO,
					IMM.INDIRIZZO ||
						DECODE(IMM.NUM_CIV,NULL,'',', ' || REPLACE(LTRIM(REPLACE(IMM.NUM_CIV, '0', ' ')),' ','0')) ||
							DECODE(IMM.SCALA,NULL,'',' Sc:' || REPLACE(LTRIM(REPLACE(IMM.SCALA, '0', ' ')), ' ', '0')) ||
								DECODE(IMM.PIANO,NULL,'',' P:' || REPLACE(LTRIM(REPLACE(IMM.PIANO, '0', ' ')), ' ', '0')) ||
									DECODE(IMM.INTERNO,NULL,'',' In:' || REPLACE(LTRIM(REPLACE(IMM.INTERNO, '0', ' ')),' ','0')) AS INDIRIZZOCOMPLETO,
					IMM.NUM_CIV AS CIVICO,
					IMM.SCALA AS SCALA,
					IMM.INTERNO AS INTERNO,
					IMM.PIANO AS PIANO,
					IMM.CATEGORIA AS CATEGORIACATASTO,
					IMM.CLASSE AS CLASSECATASTO,
					IMM.SEZIONE AS SEZIONE,
					IMM.FOGLIO AS FOGLIO,
					IMM.NUMERO AS NUMERO,
					IMM.SUBALTERNO AS SUBALTERNO,
					IMM.ZONA AS ZONA,
					IMM.PARTITA AS PARTITA,
					TO_NUMBER(IMM.CONSISTENZA) AS CONSISTENZA,
					TO_NUMBER(IMM.RENDITA_EURO) AS RENDITA,
					NULL AS REDDITODOMINICALE,
					NULL AS REDDITOAGRARIO,
					TO_NUMBER(IMM.SUPERFICIE) AS SUPERFICIE,
					IMM.NOTE AS ANNOTAZIONE,
					IMM.DATA_EFFICACIA AS DATAEFFICACIAINIZIO,
					IMM.DATA_FINE_EFFICACIA AS DATAEFFICACIAFINE,
					LPAD(NVL(IMM.NUM_CIV, '0'), 6, '0') AS CIVICOSORT,
					LPAD(NVL(IMM.SEZIONE, ' '), 3, ' ') ||
						LPAD(NVL(IMM.FOGLIO, ' '), 5, ' ') ||
							LPAD(NVL(IMM.NUMERO, ' '), 5, ' ') ||
								LPAD(NVL(IMM.SUBALTERNO, ' '), 4, ' ') ||
									LPAD(NVL(IMM.ZONA, ' '), 3, '') AS ESTREMICATASTALISORT,
					IMM.TIPO_IMMOBILE
				FROM
					IMMOBILI_CATASTO_URBANO IMM
				UNION
				SELECT DISTINCT
					TO_NUMBER(IMM.ID_IMMOBILE) AS IDIMMOBILE,
					IMM.INDIRIZZO AS INDIRIZZO,
					IMM.INDIRIZZO || DECODE(IMM.NUM_CIV,NULL,'',', ' || REPLACE(LTRIM(REPLACE(IMM.NUM_CIV, '0', ' ')),' ','0')) AS INDIRIZZOCOMPLETO,
					IMM.NUM_CIV AS CIVICO,
					NULL AS SCALA,
					NULL AS INTERNO,
					NULL AS PIANO,
					NULL AS CATEGORIACATASTO,
					IMM.CLASSE AS CLASSECATASTO,
					IMM.SEZIONE AS SEZIONE,
					IMM.FOGLIO AS FOGLIO,
					IMM.NUMERO AS NUMERO,
					IMM.SUBALTERNO AS SUBALTERNO,
					'' AS ZONA,
					IMM.PARTITA AS PARTITA,
					NULL AS CONSISTENZA,
					NULL AS RENDITA,
					TO_NUMBER(IMM.REDDITO_DOMINICALE_EURO) AS REDDITODOMINICALE,
					TO_NUMBER(IMM.REDDITO_AGRARIO_EURO) AS REDDITOAGRARIO,
					((TO_NUMBER(NVL(IMM.ETTARI,'0')) * 10000) + (TO_NUMBER(NVL(IMM.ARE,'0')) * 100) + TO_NUMBER(NVL(IMM.CENTIARE,'0'))) AS SUPERFICIE,
					'' AS ANNOTAZIONE,
					IMM.DATA_EFFICACIA AS DATAEFFICACIAINIZIO,
					IMM.DATA_FINE_EFFICACIA AS DATAEFFICACIAFINE,
					LPAD(NVL(IMM.NUM_CIV,'0'),6,'0') AS CIVICOSORT,
					LPAD(NVL(IMM.SEZIONE,' '),3,' ') ||
						LPAD(NVL(IMM.FOGLIO,' '),5,' ') ||
							LPAD(NVL(IMM.NUMERO,' '),5,' ') ||
								LPAD(NVL(IMM.SUBALTERNO,' '),4,' ') || '' AS ESTREMICATASTALISORT,
					'T' AS TIPO_IMMOBILE
				FROM
					IMMOBILI_CATASTO_TERRENI IMM
				)
				${sqlFiltri}
				ORDER BY TIPO_IMMOBILE, ESTREMICATASTALISORT
			"""

		sqlTotali = """
				SELECT COUNT(*) AS TOT_COUNT
				FROM ($sql)
				"""

		int totalCount = 0
		int pageCount = 0

		def params = [:]
		params.max = pageSize ?: 25
		params.activePage = activePage ?: 0
		params.offset = params.activePage * params.max

		def totali = eseguiQuery("${sqlTotali}", filtri, params, true)[0]

		def totals = [
				totalCount: totali.TOT_COUNT,
		]

		def results = eseguiQuery("${sql}", filtri, params)

		def records = []

		results.each {

			def record = [:]

			record.id = it['IDIMMOBILE']
			record.tipoOggetto = it['TIPO_IMMOBILE']

			record.indirizzo = it['INDIRIZZO']
			record.indirizzoCompleto = it['INDIRIZZOCOMPLETO']
			record.civico = it['CIVICO']
			record.scala = it['SCALA']
			record.interno = it['INTERNO']
			record.piano = it['PIANO']
			record.categoriaCatasto = it['CATEGORIACATASTO']
			record.classeCatasto = it['CLASSECATASTO']
			record.sezione = it['SEZIONE']
			record.foglio = it['FOGLIO']
			record.numero = it['NUMERO']
			record.subalterno = it['SUBALTERNO']

			record.zona = it['ZONA']
			record.partita = it['PARTITA']
			record.consistenza = it['CONSISTENZA']
			record.rendita = it['RENDITA']
			record.redditoDominicale = it['REDDITODOMINICALE']
			record.redditoAgrario = it['REDDITOAGRARIO']
			record.superficie = it['SUPERFICIE']
			record.annotazione = it['ANNOTAZIONE']
			record.dataEfficaciaInizio = it['DATAEFFICACIAINIZIO']?.format("dd/MM/yyyy")
			record.dataEfficaciaFine = it['DATAEFFICACIAFINE']?.format("dd/MM/yyyy")

			record.civicoSort = it['CIVICOSORT']
			record.estremiCatastaliSort = it['ESTREMICATASTALISORT']

			records << record
		}

		return [totalCount: totals.totalCount, records: records]
	}

	///
	/// *** Esegue query
	///
	private eseguiQuery(def query, def filtri, def paging, def wholeList = false) {

		filtri = filtri ?: [:]

		if (!query || query.isEmpty()) {
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

	/// ############################################################################################################################

	///
	/// *** Parse elenco oggetti da WebGIS
	///
	def parseElencoOggetti(String idOggetti) {

		def listaOggetti = []

		String idOggettiCrypt = idOggetti

		def oggettoDummy = [

				codCom  : "Z999",
				intIdCom: 10540,
				tipoCat : 0,
				sezCat  : "_",
				fogCat  : "0",
				numCat  : "0",
				subCat  : "-"
		]

		String codCom
		String intIdCom
		String tipoCat
		String sezCat
		String fogCat
		String numCat
		String subCat

		try {
			idOggetti = decodeString(idOggettiCrypt)

			String[] isSingoli = idOggetti.split("\\]")
			String idSingolo
			String idPorzione

			for (int item = 0; item < isSingoli.length; item++) {

				idSingolo = isSingoli[item]

				String[] idPorzioni = idSingolo.split("\\[")

				int numPorzioni = idPorzioni.length

				def oggetto = [:]

				/// idPorzioni[0]	-> Always empty

				codCom = (numPorzioni > 1) ? idPorzioni[1] : oggettoDummy.codCom
				intIdCom = (numPorzioni > 2) ? idPorzioni[2] : oggettoDummy.intIdCom
				tipoCat = (numPorzioni > 3) ? idPorzioni[3] : oggettoDummy.tipoCat
				sezCat = (numPorzioni > 4) ? idPorzioni[4] : oggettoDummy.sezCat
				fogCat = (numPorzioni > 5) ? idPorzioni[5] : oggettoDummy.fogCat
				numCat = (numPorzioni > 6) ? idPorzioni[6] : oggettoDummy.numCat
				subCat = (numPorzioni > 7) ? idPorzioni[7] : oggettoDummy.subCat

				codCom = codCom.toString()
				intIdCom = intIdCom.toString()
				tipoCat = tipoCat.toInteger()
				sezCat = sezCat.toString()
				fogCat = fogCat.toString()
				numCat = numCat.toString()
				subCat = subCat.toString()

				if (sezCat.length() < 1) sezCat = null
				if (sezCat == "_") sezCat = ""
				if (sezCat == ".") sezCat = ""
				if (sezCat == "*") fogCat = null

				if (fogCat == "_") fogCat = ""
				if (fogCat == "*") fogCat = null

				if (numCat == "_") numCat = ""
				if (numCat == "*") numCat = null

				if (subCat == "-") subCat = ""
				if (subCat.length() < 1) subCat = null
				if (subCat == "*") subCat = null

				oggetto.codCom = codCom
				oggetto.intIdCom = intIdCom
				oggetto.tipoCat = tipoCat
				oggetto.sezCat = sezCat
				oggetto.fogCat = fogCat
				oggetto.numCat = numCat
				oggetto.subCat = subCat

				listaOggetti << oggetto
			}
		}
		catch (Exception ex) {

			listaOggetti = []
			listaOggetti << oggettoDummy

			String resultMsg = "Si e' verificato un errore : " + ex.toString()
			String title = "Errore di comunizazione"
			String message = "Attenzione :\n\nSi e' verificato un errore di comunicazione con il WebGIS !\n\n" + resultMsg + " !"
			Messagebox.show(message, title, Messagebox.OK, Messagebox.QUESTION)
		}

		return listaOggetti
	}

	/// ############################################################################################################################

	private String decodeString(String original) {

		AESCrypter aesCrypter = new AESCrypter()
		String key = "TR4_WebGIS"

		String crypted
		String base
		String baseCheck
		String result = ""
		boolean cryptedText = false

		int length = original.length()

		if (length > 10) {

			if (original[0] == 'T') {

				cryptedText = true

				base = original.substring(1, 3)
				crypted = original.substring(3, length - 2)

				crypted = aesCrypter.decrypt(crypted, key)
				length = crypted.length()

				baseCheck = crypted.substring((length - 2), length)

				if (baseCheck == base)
					result = crypted.substring(2, length - 2)
			}
		}

		if (!cryptedText && (length > 5) && (original[0] == '[')) {
			result = original
		}

		return result
	}

	/// ############################################################################################################################

	///
	/// *** Elabora richiesta scomponendo in pacchetti di oggetti
	///
	private String richiestaWebGIS(String urlAPI, String tipoRichiesta, String attributiOggetto, def elencoOggetti) {

		String resultMsg = ""

		String maxOggettiStr = this.numOggettiSincroniaGIS?.valore ?: "25"

		int maxOggetti = Integer.parseInt(maxOggettiStr)
		int totaleOggetti = elencoOggetti.size()

		int oggettoDa
		int oggettoA
		int conteggio

		String codiceEnte = this.codiceEnte

		String richiestaOggetto
		String richiestaOggetti

		String result

		log.info "Richiesta : ${tipoRichiesta} -> ${attributiOggetto}"

		if (maxOggetti < 1) maxOggetti = 1
		if (maxOggetti > 100) maxOggetti = 100

		oggettoA = 0

		richiestaOggetti = ""
		conteggio = 0

		try {
			elencoOggetti.each {

				richiestaOggetto = preparaRichiestaOggetto(it, attributiOggetto)
				richiestaOggetti += richiestaOggetto

				conteggio++

				if (conteggio >= maxOggetti) {

					result = elaboraRichiesta(tipoRichiesta, richiestaOggetti, urlAPI)
					if (result.indexOf("--") >= 0)
						throw new Exception(result)

					oggettoDa = oggettoA + 1
					oggettoA = oggettoA + conteggio
					log.info "Oggetti inviati : ${oggettoDa} -> ${oggettoA} su ${totaleOggetti}"

					richiestaOggetti = ""
					conteggio = 0
				}
			}

			if (conteggio != 0) {

				result = elaboraRichiesta(tipoRichiesta, richiestaOggetti, urlAPI)
				if (result.indexOf("--") >= 0)
					throw new Exception(result)

				oggettoDa = oggettoA + 1
				oggettoA = oggettoA + conteggio
				log.info "Oggetti inviati : ${oggettoDa} -> ${oggettoA} su ${totaleOggetti}"
			}
		}
		catch (Exception ex) {

			resultMsg = ex.toString()
		}

		return resultMsg
	}

	///
	/// *** Legge da DB elenco operazioni da eseguire
	///
	private def elencoOperazioniWebGIS() {

		String query = """SELECT ID, VISTA, FILTRO, FUNZIONE, NVL(DISABILITATO,'-') AS DISABILITATO FROM GIS_VISTE ORDER BY ID"""

		def results = sessionFactory.currentSession.createSQLQuery(query).with {

			resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
			list()
		}

		def listaOperazioni = []

		results.each {

			def operazione = [:]

			operazione.id = it['ID'].toLong()
			operazione.vista = it['VISTA'].toString()
			operazione.filtro = (it['FILTRO'] ?: '').toString()
			operazione.funzione = it['FUNZIONE'].toString()
			operazione.disabilitato = it['DISABILITATO'].toString()

			listaOperazioni << operazione
		}

		return listaOperazioni
	}

	///
	/// *** Legge da DB elenco oggetti da elaborare
	///
	private def elencoOggettiWebGIS(String vista, String filtro, boolean mergeSubs) {

		String query

		String extraFilter = ""

		if ((filtro != null) && (filtro.size() > 0)) {

			extraFilter = " WHERE ${filtro} "
		}

		///
		/// Le query fanno un sort per far si che arrivino prima gli edifici con sezione.
		///		In questo modo si evitano doppioni dovuti a conversione CU -> CT
		///
		if (mergeSubs) {

			query = """ SELECT """ +
					"""		TIPO_OGGETTO, """ +
					"""		NVL(SEZIONE,' ') AS SEZIONE_FIXED, """ +
					"""     NVL(FOGLIO,' ') AS FOGLIO_FIXED, """ +
					"""     NVL(NUMERO,' ') AS NUMERO_FIXED, """ +
					"""		MAX(NVL(SUBALTERNO,'-')) AS SUBALTERNO_FIXED """ +
					"""	FROM ${vista} """ +
					""" ${extraFilter} """ +
					"""	GROUP BY """ +
					"""		TIPO_OGGETTO, SEZIONE, FOGLIO, NUMERO """ +
					""" ORDER BY 1 DESC, 2 DESC"""
		} else {

			query = """ SELECT """ +
					"""		TIPO_OGGETTO, """ +
					"""		NVL(SEZIONE,' ') AS SEZIONE_FIXED, """ +
					"""     NVL(FOGLIO,' ') AS FOGLIO_FIXED, """ +
					"""     NVL(NUMERO,' ') AS NUMERO_FIXED, """ +
					"""		NVL(SUBALTERNO,' ') AS SUBALTERNO_FIXED """ +
					"""	FROM ${vista} """ +
					""" ${extraFilter} """ +
					""" ORDER BY 1 DESC, 2 DESC"""
		}

		def results = sessionFactory.currentSession.createSQLQuery(query).with {

			resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
			list()
		}

		def listaOggetti = []

		String sezione
		String foglio
		String numero
		String sub

		results.each {

			def oggetto = [:]

			oggetto.tipoOggetto = it['TIPO_OGGETTO'].toLong()

			sezione = it['SEZIONE_FIXED'].toString()
			foglio = it['FOGLIO_FIXED'].toString()
			numero = it['NUMERO_FIXED'].toString()
			sub = it['SUBALTERNO_FIXED'].toString()

			sezione = sezione.replace("&", "_")
			foglio = foglio.replace("&", "_")
			numero = numero.replace("&", "_")
			sub = sub.replace("&", "_")
			sezione = sezione.replace("<", "_")
			foglio = foglio.replace("<", "_")
			numero = numero.replace("<", "_")
			sub = sub.replace("<", "_")
			sezione = sezione.replace(">", "_")
			foglio = foglio.replace(">", "_")
			numero = numero.replace(">", "_")
			sub = sub.replace(">", "_")

			oggetto.sezione = sezione
			oggetto.foglio = foglio
			oggetto.numero = numero
			oggetto.sub = sub

			listaOggetti << oggetto
		}

		return listaOggetti
	}

	///
	/// *** Prepara elenco oggetti e crea richiesta
	///		Riporta Token notifica oppure "--" + Messaggio se errore
	///
	private String addOggettiWebGIS(def oggetti, String tipoRichiesta) {

		int conteggio

		String tipoOggetto
		String sezione
		String foglio
		String numero

		String richiestaOggetto
		String codici = ""

		String token = "---"

		String urlAPI = this.indirizzoWebGISServizio?.valore

		conteggio = 0
		oggetti.each {

			richiestaOggetto = preparaRichiestaOggetto(it, "")
			codici += richiestaOggetto

			conteggio++
		}

		if (conteggio < 1)
			return ""

		token = elaboraRichiesta(tipoRichiesta, codici, urlAPI)

		return token
	}

	///
	/// *** Elabora richiesta per servizio specificato - Per tentativi
	///
	private String elaboraRichiesta(String tipoRichiesta, String oggetti, String url) {

		String result
		int tentativo = 10
		int retry = 1

		while (1 == 1) {

			result = elaboraRichiestaTentativo(tipoRichiesta, oggetti, url)
			if (result.indexOf("--") < 0) break

			if (--tentativo < 0x00) break

			log.info "Errore inviando : riprovo (${retry}). . . "

			Thread.sleep(500)

			retry++
		}
		return result
	}

	///
	/// *** Elabora richiesta per servizio specificato
	///
	private String elaboraRichiestaTentativo(String tipoRichiesta, String oggetti, String url) {

		String token = "---"

		int connectTimeout = 10000
		int readTimeout = 20000

		String codiceEnte = this.codiceEnte

		def xmlOggetti = XmlUtil.escapeXml "<ente>" +
				"<codice>${codiceEnte}</codice>" +
				"<tipoRichiesta>${tipoRichiesta}</tipoRichiesta>" +
				"<oggetti>${oggetti}</oggetti>" +
				"</ente>"
		def client = new SOAPClient(url)

		client.httpClient.sslTrustAllCerts = true
		client.httpClient.connectTimeout = connectTimeout
		client.httpClient.readTimeout = readTimeout

		try {
			def response = client.send("""<?xml version="1.0" encoding="utf-8"?>""" +
					"""<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" """ +
					"""xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">""" +
					"""<soap:Body><getLinkId xmlns="http://tempuri.org/"><xml>${xmlOggetti}</xml></getLinkId></soap:Body>""" +
					"""</soap:Envelope>""")

			if ((response != null) && (response.httpResponse != null)) {

				def httpResponse = response.httpResponse
				def statusCode = httpResponse.statusCode

				if (statusCode == 200) {

					token = response.getBody()
				} else {
					token = response.getFault()
					token = "--> Errore (" + statusCode.toString() + ") : ${token}"
				}
			}
		}
		catch (Exception ex) {

			token = "--> Errore di protocollo : " + ex.toString()
		}

		return token
	}

	///
	/// Crea oggetto per richiesta con attributi
	///
	private String preparaRichiestaOggetto(def oggetto, String attributiOggetto) {

		String richiestaOggetto

		long tipoOggettoTR4

		String tipoOggetto
		String sezione
		String foglio
		String numero

		String codiceEnte = this.codiceEnte

		tipoOggettoTR4 = oggetto.tipoOggetto ?: -1
		sezione = (oggetto.sezione != null) ? oggetto.sezione.trim() : ""
		foglio = (oggetto.foglio != null) ? oggetto.foglio.trim() : ""
		numero = (oggetto.numero != null) ? oggetto.numero.trim() : ""

		tipoOggetto = tipoOggettoWebGISDaTipoTR4(tipoOggettoTR4)

		richiestaOggetto = "<oggetto>" +
				"<tipoOggetto>${tipoOggetto}</tipoOggetto>" +
				"<identificativi>" +
				"<comuneCatastale>${codiceEnte}</comuneCatastale>" +
				"<sezioneCatastale>${sezione}</sezioneCatastale>" +
				"<foglioCatastale>${foglio}</foglioCatastale>" +
				"<particellaCatastale>${numero}</particellaCatastale>" +
				"</identificativi>" +
				"${attributiOggetto}" +
				"</oggetto>"

		return richiestaOggetto
	}

	///
	/// Estrae Tipo Oggetto WebGIS da TipoOggetto TR4
	///
	private String tipoOggettoWebGISDaTipoTR4(long tipoOggettoTR4) {

		String tipoOggetto = ""

		//	1	TERRENO AGRICOLO
		//	2	AREA FABBRICABILE
		//	3	FABBRICATO CON RENDITA CATASTALE
		//	4	FABBRICATO CON VALORE DETERMINATO
		//	5	OGGETTO TARSU
		//	6	OGGETTO COSAP
		//	7	OGGETTO ICP
		//	8	OGGETTO ICIAP
		//	50	OGGETTO TARES
		//	55	FABBRICATO RURALE

		switch (tipoOggettoTR4) {
			default:
				tipoOggetto = "CT"
				break
			case [1, 2]:
				tipoOggetto = "CT"
				break
			case [-1, 3, 4]:
				tipoOggetto = "CU"
				break
		}

		return tipoOggetto
	}

	///
	/// Parse URL estra ente ed accesso se presenti
	///
	private String parseUrl(String url) {

		int specIndexQ
		int specIndexA
		int specIndex

		specIndexQ = url.indexOf("?ACCESS=ANONYMOUS")
		specIndexA = url.indexOf("&ACCESS=ANONYMOUS")
		specIndex = Math.max(specIndexQ, specIndexA)
		if (specIndex > 0) {

			this.codiceAccesso = url.substring(specIndex + 1, url.length())
			url = url.substring(0, specIndex)
		}

		specIndexQ = url.indexOf("?CODCOM=")
		specIndexA = url.indexOf("&CODCOM=")
		specIndex = Math.max(specIndexQ, specIndexA)
		if (specIndex > 0) {

			this.codiceEnte = url.substring(specIndex + 8, url.length())
			url = url.substring(0, specIndex)
		}

		specIndexQ = url.indexOf("?AUTHENTICATION=")
		specIndexA = url.indexOf("&AUTHENTICATION=")
		specIndex = Math.max(specIndexQ, specIndexA)
		if (specIndex > 0) {

			this.ticketAccesso = url.substring(specIndex + 16, url.length())
			url = url.substring(0, specIndex)
		}
		
		return url
	}

	///
	/// Ricava ente da configurazione database
	///		Riporta "COMUNEDEMO" se non determinabile
	///
	private def codiceEnte() {

		String codiceEnte = 'COMUNEDEMO'

		Ad4ComuneDTO comune = datiGeneraliService.getComuneCliente()
		if (comune != null) codiceEnte = comune.siglaCodiceFiscale

		return codiceEnte
	}

	///
	/// *** Imposta sistema per configurazione di Debug
	///
	private def impostazioniPerDebug() {

		this.indirizzoWebAPIServizio = [valore: "http://172.16.1.2/UrbeWebApi/ADS/ADS.asmx?CODCOM=L567"]
		this.indirizzoWebGISServizio = [valore: "http://172.16.1.2/WebGis/ADS/ADS.asmx"]
		this.indirizzoWebGISURL = [valore: "http://172.16.1.2/WebGis/default.aspx?CODCOM=L567"]
		// &ACCESS=ANONYMOUS";
	};
}
