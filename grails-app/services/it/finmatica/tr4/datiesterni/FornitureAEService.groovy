package it.finmatica.tr4.datiesterni

import grails.orm.PagedResultList
import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.datiContabili.DatiContabiliService
import it.finmatica.ad4.dizionari.Ad4Comune
import it.finmatica.ad4.dizionari.Ad4Provincia
import it.finmatica.tr4.CfaAccTributi
import it.finmatica.tr4.CfaProvvisorioEntrataTributi
import it.finmatica.tr4.dto.CfaAccTributiDTO
import it.finmatica.tr4.dto.CfaProvvisorioEntrataTributiDTO
import it.finmatica.tr4.dto.datiesterni.FornituraAEDTO
import org.hibernate.criterion.Restrictions
import org.hibernate.transform.AliasToEntityMapResultTransformer
import org.hibernate.FetchMode

import java.text.DecimalFormat
import java.text.SimpleDateFormat

@Transactional
class FornitureAEService {

	static transactional = false

	def dataSource
	def sessionFactory

	def commonService
	DatiContabiliService datiContabiliService

	///
	/// Riporta lista Progressivi documenti di tributi da Forniture Ag. Entrate
	///
	def getListaProgrDocPerFornitureAE(def codiciTributo, Boolean flagProvincia) {

		String tipiTributo = ""

		String sqlFiltri = ""
		String sql

		def filtri = [:]

		filtri << ['titoloDocumento' : (flagProvincia) ? 38 : 21]

		if (codiciTributo.size() > 0) {

			tipiTributo = "'" + elencoTributi.join("','") + "'"
			sqlFiltri += "AND FORN.CODICE_TRIBUTO IN (${codiciTributo}) "
		}

		sql = """
				SELECT
				  DOCUMENTO_ID,
				  DOCUMENTO_ID || ' - ' || NOME_DOCUMENTO || ' del ' || TO_CHAR(DATA_VARIAZIONE,'dd/mm/yyyy') as DESCRIZIONE
				FROM
				  DOCUMENTI_CARICATI DOCA
				WHERE
				  DOCA.TITOLO_DOCUMENTO = :titoloDocumento AND
				  DOCA.STATO = 2 AND 
				  EXISTS
				  (SELECT 'x'
					  FROM FORNITURE_AE FORN
					  WHERE
						FORN.DOCUMENTO_ID = DOCA.DOCUMENTO_ID
						${sqlFiltri}
				  )
				ORDER BY 1 DESC	
		"""

        def results = eseguiQuery("${sql}", filtri, null, true)

        def records = []

        results.each {

			def record = [:]

			record.codice = it['DOCUMENTO_ID']
			record.descrizione = it['DESCRIZIONE']

			records << record
		}

		return records
	}

	///
	/// Riporta elenco date bonifico per ProgDoc specificato
	///
	def getListaDateBonificoForniture(def progDoc, Boolean flagProvincia) {

		def filtri = [:]

		filtri << ['progDoc': progDoc as Integer]
		filtri << ['tipoRecord' : (flagProvincia) ? 'D' : 'G1']

		String sql = """SELECT DATA_BONIFICO
						FROM FORNITURE_AE FORN
						WHERE FORN.DOCUMENTO_ID = :progDoc
						  AND FORN.TIPO_RECORD = :tipoRecord
						GROUP BY DATA_BONIFICO ORDER BY 1 ASC
		"""

		def results = eseguiQuery("${sql}", filtri, null, true)

		def records = []

		results.each {
			records << it['DATA_BONIFICO']
		}

		return records
	}

	///
	/// Riporta elenco porzioni della fornitura
	///
	def getPorzioniForniture(def progDoc, Boolean flagProvincia) {

		def filtri = [:]

		filtri << ['progDoc': progDoc as Integer]
		filtri << ['tipoRecord' : (flagProvincia) ? 'D' : 'G1']

		String sql = """SELECT	DOCUMENTO_ID,
								DATA_FORNITURA,
								PROGR_FORNITURA,
								DATA_RIPARTIZIONE,
								PROGR_RIPARTIZIONE,
								DATA_BONIFICO
						FROM	FORNITURE_AE FORN
						WHERE	FORN.TIPO_RECORD = :tipoRecord AND
								FORN.DOCUMENTO_ID = :progDoc 
						GROUP BY
								DOCUMENTO_ID,
								DATA_FORNITURA,
								PROGR_FORNITURA,
								DATA_RIPARTIZIONE,
								PROGR_RIPARTIZIONE,
								DATA_BONIFICO
						ORDER BY 2, 4, 6 ASC
		"""

		def results = eseguiQuery("${sql}", filtri, null, true)

		def records = []

		SimpleDateFormat ft = new SimpleDateFormat("dd-MM-yyyy")

		results.each {

			def record = [:]

			record.documentoId = it['DOCUMENTO_ID']
			record.dataFornitura = it['DATA_FORNITURA']
			record.progFornitura = it['PROGR_FORNITURA'] as Short
			record.dataRipartizione = it['DATA_RIPARTIZIONE']
			record.progRipartizione = it['PROGR_RIPARTIZIONE'] as Short
			record.dataBonifico = it['DATA_BONIFICO']
			
			record.codice = (record.documentoId as String) + "_" + (record.progFornitura as String) + "_" + 
																	(record.progRipartizione as String) + "_" + ft.format(record.dataBonifico)

			record.descrizione = "Forn. " + ft.format(record.dataFornitura) + " - " + record.progFornitura +
					", Rip. " + ft.format(record.dataRipartizione) + " - " + record.progRipartizione +
					", Data Bon. " + ft.format(record.dataBonifico)

			records << record
		}

		return records
	}

	///
	/// *** Estra elenco forniture da filtri
	///
	def listaForniture(def filtri, int pageSize, int activePage) {

		boolean extended = false

		PagedResultList elencoForniture = FornituraAE.createCriteria().list(max: pageSize, offset: pageSize * activePage) {

			eq("tipoRecord", filtri.tipoRecord ?: 'G1')

			if (filtri.progDoc) {
				eq("documentoCaricato.id", filtri.progDoc as Long)
			}
			if (filtri.progDocDa) {
				ge("documentoCaricato.id", filtri.progDocDa as Long)
			}
			if (filtri.progDocA) {
				le("documentoCaricato.id", filtri.progDocA as Long)
			}

			if (filtri.dataFornitura) {
				eq("dataFornitura", filtri.dataFornitura)
			}
			if (filtri.dataFornituraDa) {
				ge("dataFornitura", filtri.dataFornituraDa)
				extended = true
			}
			if (filtri.dataFornituraA) {
				le("dataFornitura", filtri.dataFornituraA)
				extended = true
			}

			if (filtri.progFornitura) {
				eq("progrFornitura", filtri.progFornitura)
			}

			if (filtri.dataRipartizione) {
				eq("dataRipartizione", filtri.dataRipartizione)
			}
			if (filtri.dataRipartizioneDa) {
				ge("dataRipartizione", filtri.dataRipartizioneDa)
				extended = true
			}
			if (filtri.dataRipartizioneA) {
				le("dataRipartizione", filtri.dataRipartizioneA)
				extended = true
			}

			if (filtri.progRipartizione) {
				eq("progrRipartizione", filtri.progRipartizione)
			}

			if (filtri.dataBonifico) {
				eq("dataBonifico", filtri.dataBonifico)
			}
			if (filtri.dataBonificoDa) {
				ge("dataBonifico", filtri.dataBonificoDa)
				extended = true
			}
			if (filtri.dataBonificoA) {
				le("dataBonifico", filtri.dataBonificoA)
				extended = true
			}
			
			if (filtri.dataRipartizioneOrigDa) {
				ge("dataRipartizioneOrig", filtri.dataRipartizioneOrigDa)
			}
			if (filtri.dataRipartizioneOrigA) {
				le("dataRipartizioneOrig", filtri.dataRipartizioneOrigA)
			}

			if (filtri.dataBonificoOrigDa) {
				ge("dataBonificoOrig", filtri.dataBonificoOrigDa)
			}
			if (filtri.dataBonificoOrigA) {
				le("dataBonificoOrig", filtri.dataBonificoOrigA)
			}
			
			if (filtri.codEnteComunale) {
				ilike("codEnteComunale", filtri.codEnteComunale)
			}
			if (filtri.codFiscale) {
				ilike("codFiscale", filtri.codFiscale)
			}
			if (filtri.codiceTributoDa) {
				ge("codTributo", filtri.codiceTributoDa as String)
			}
			if (filtri.codiceTributoA) {
				le("codTributo", filtri.codiceTributoA as String)
			}
			if (filtri.annoRifDa) {
				ge("annoRif", filtri.annoRifDa as Short)
			}
			if (filtri.annoRifA) {
				le("annoRif", filtri.annoRifA as Short)
			}
			if (filtri.dataRiscossioneDa) {
				ge("dataRiscossione", filtri.dataRiscossioneDa)
			}
			if (filtri.dataRiscossioneA) {
				le("dataRiscossione", filtri.dataRiscossioneA)
			}

			if (filtri.filtroAccertato) {
				if (filtri.filtroAccertato != 2) {
					add(Restrictions.isNotNull("numeroAcc"))
				} else {
					add(Restrictions.isNull("numeroAcc"))
				}
			}
			if (filtri.filtroProvvisorio) {
				if (filtri.filtroProvvisorio != 2) {
					add(Restrictions.isNotNull("numeroProvvisorio"))
				} else {
					add(Restrictions.isNull("numeroProvvisorio"))
				}
			}

			if(extended) {
				order('codEnteComunale')
				order('codFiscale')
				order('dataFornitura')
				order('dataRipartizione')
				order('dataBonifico')
				order('progressivo')
			}
			else {
				order('documentoCaricato.id')
				order('progressivo')
			}
		}

		String sqlProgDoc = ""
		
		def filtriTrib = [:]

		filtriTrib << [tipo_record: filtri.tipoRecord ?: 'G1']
		
		if(filtri.progDoc) {
			filtriTrib << [ progDoc: filtri.progDoc ?: 0]
			sqlProgDoc += " AND DOCUMENTO_ID = :progDoc "
		}
		if(filtri.progDocDa) {
			filtriTrib << [ progDocDa: filtri.progDocDa ?: 0]
			sqlProgDoc += " AND DOCUMENTO_ID >= :progDocDa "
		}
		if(filtri.progDocA) {
			filtriTrib << [ progDocA: filtri.progDocA]
			sqlProgDoc += " AND DOCUMENTO_ID <= :progDocA "
		}

		String sql = """SELECT	NVL(ANNO_RIF,EXTRACT (YEAR FROM NVL(DATA_BONIFICO_ORIG,DATA_FORNITURA))) AS ANNO_RIF,
								TIPO_IMPOSTA,
								MAX(F_DESCRIZIONE_TITR(DECODE(TIPO_IMPOSTA
									,'I','ICI'
									,'O','TOSAP'
									,'T','TARSU'
									,'S','ISCOP'
									,'R','ISOGG'
									,'A','TARES'
									,'U','TASI'
									,'M','IMIS'
									,'TEF','TEFA'
									,TIPO_IMPOSTA),ANNO_RIF)) AS DESCR_TRIBUTO
						FROM	FORNITURE_AE
						WHERE	TIPO_RECORD = :tipo_record
								${sqlProgDoc}
						GROUP BY NVL(ANNO_RIF,EXTRACT (YEAR FROM NVL(DATA_BONIFICO_ORIG,DATA_FORNITURA))), TIPO_IMPOSTA
		"""

		def results = eseguiQuery("${sql}", filtriTrib, null, true)

		def descrTributi = []

		results.each {

			def descrTributo = [:]

			descrTributo.annoRif = it['ANNO_RIF']
			descrTributo.tipoImposta = it['TIPO_IMPOSTA']
			descrTributo.descrizione = it['DESCR_TRIBUTO']

			descrTributi << descrTributo
		}

		def records = []

		Short annoRif
		String tipoImposta
		Double credito
		Double debito
		Short num
		Short den

		String patternValuta = "€ #,###.00"
		DecimalFormat valuta = new DecimalFormat(patternValuta)
		valuta.setMinimumIntegerDigits(1)
		DecimalFormat numero = new DecimalFormat("#,##0.00")
		DecimalFormat codProv = new DecimalFormat("000")

		def elencoEnti = []
		def elencoProvince = []
		String siglaEnte;

		elencoForniture.list.each {

			def record = [:]

			record.dto = it.toDTO()

			tipoImposta = it.tipoImposta
			
			annoRif = it.annoRif
			if(!annoRif) {
				Calendar calendarForyear = Calendar.getInstance();
				calendarForyear.setTime(it.dataBonificoOrig ?: it.dataFornitura)
				annoRif = calendarForyear.get(Calendar.YEAR)
			}
			
			def descrTributo = descrTributi.find { it.annoRif == annoRif && it.tipoImposta == tipoImposta }

			if (descrTributo != null) {
				record.descrTributo = descrTributo.descrizione
			} else {
				record.descrTributo = tipoImposta
			}

			if ((it.rateazione ?: 0) != 0) {
				num = ((it.rateazione - (it.rateazione % 100)) / 100) as Short
				den = (it.rateazione % 100) as Short
				record.rateazione = (num as String) + ' / ' + (den as String)
			} else {
				record.rateazione = ''
			}

			debito = (it.importoDebito ?: 0) as Double
			credito = (it.importoCredito ?: 0) as Double

			if (it.codValuta == 'EUR') {
				record.importoDebito = valuta.format(debito)
				record.importoCredito = valuta.format(credito)
			} else {
				record.importoDebito = it.codValuta + " " + numero.format(debito)
				record.importoCredito = it.codValuta + " " + numero.format(credito)
			}

			String desStato = null
			
			switch(it.tipoRecord) {
				default :
					break;
				case 'G2' :
					switch(it.stato) {
						default :
							desStato = "Altro : " + it.stato;
							break;
						case '9' :
							desStato = "-";
							break;
						case 'A' :
							desStato = "Accredito disposto";
							break;
						case 'B' :
							desStato = "Accredito sospeso";
							break;
						case 'C' :
							desStato = "Accredito riemesso";
							break;
					}
					break;
				case 'G5' :
					switch(it.stato) {
						default :
							desStato = "Altro : " + it.stato;
							break;
						case '9' :
							desStato = "-";
							break;
						case 'A' :
							desStato = "Mandato finalizzato";
							break;
						case 'B' :
							desStato = "Mandato scartato";
							break;
						case 'C' :
							desStato = "Mandato stornato";
							break;
						case 'D' :
							desStato = "Mandato riemesso";
							break;
					}
					break;
			}
			record.desStato = desStato;

			siglaEnte = it.codEnteComunale ?: ''

			if(!siglaEnte.isEmpty()) {
				def enteComunale = elencoEnti.find { it.siglaCFis == siglaEnte }
				if(enteComunale == null) {
					enteComunale = getDatiComuneDaSiglaCFis(siglaEnte)
					elencoEnti << enteComunale
				}

				record.enteComunale = enteComunale.siglaCFis + ' - ' + enteComunale.descrizione
			}
			else {
				record.enteComunale = siglaEnte
			}

			siglaEnte = ''

			if(it.codProvincia) {
				def provincia = elencoProvince.find { prov -> prov.id == it.codProvincia }
				if (provincia == null) {
					provincia = Ad4Provincia.get(it.codProvincia)?.toDTO()
					if(provincia) {
						elencoProvince << provincia
					}
				}

				if(provincia) {
					siglaEnte = codProv.format(it.codProvincia) + ' - ' + provincia.denominazione
				}
				else {
					siglaEnte = codProv.format(it.codProvincia) + ' - ' + 'Sconosciuta'
				}
			}

			record.enteProvinciale = siglaEnte

			credito = it.importoNetto ?: 0
			debito = it.importoIfel ?: 0

			record.importoIFELPrecedente = debito
			record.importoLordo = credito + debito
			
			records << record
		}

		return [lista: records, totale: elencoForniture.totalCount]
	}

	///
	/// Duplica fornitura
	///
	def duplicaFornitura(FornituraAEDTO originale) {

		FornituraAEDTO fornitura = new FornituraAEDTO()

		fornitura.documentoCaricato = originale.documentoCaricato
		fornitura.progressivo = 0

		fornitura.tipoRecord = originale.tipoRecord
		fornitura.dataFornitura = originale.dataFornitura
		fornitura.progrFornitura = originale.progrFornitura

		fornitura.dataRipartizione = originale.dataRipartizione
		fornitura.progrRipartizione = originale.progrRipartizione
		fornitura.dataBonifico = originale.dataBonifico
		fornitura.progrDelega = originale.progrDelega
		fornitura.progrRiga = originale.progrRiga
		fornitura.codEnte = originale.codEnte
		fornitura.tipoEnte = originale.tipoEnte
		fornitura.cab = originale.cab
		fornitura.codFiscale = originale.codFiscale
		fornitura.flagErrCodFiscale = originale.flagErrCodFiscale
		fornitura.dataRiscossione = originale.dataRiscossione
		fornitura.codEnteComunale = originale.codEnteComunale
		fornitura.codTributo = originale.codTributo
		fornitura.flagErrCodTributo = originale.flagErrCodTributo
		fornitura.rateazione = originale.rateazione
		fornitura.annoRif = originale.annoRif
		fornitura.flagErrAnno = originale.flagErrAnno
		fornitura.codValuta = originale.codValuta
		fornitura.importoDebito = originale.importoDebito
		fornitura.importoCredito = originale.importoCredito
		fornitura.ravvedimento = originale.ravvedimento
		fornitura.immobiliVariati = originale.immobiliVariati
		fornitura.acconto = originale.acconto
		fornitura.saldo = originale.saldo
		fornitura.numFabbricati = originale.numFabbricati
		fornitura.flagErrDati = originale.flagErrDati
		fornitura.detrazione = originale.detrazione
		fornitura.cognomeDenominazione = originale.cognomeDenominazione
		fornitura.codFiscaleOrig = originale.codFiscaleOrig
		fornitura.nome = originale.nome
		fornitura.sesso = originale.sesso
		fornitura.dataNas = originale.dataNas
		fornitura.comuneStato = originale.comuneStato
		fornitura.provincia = originale.provincia
		fornitura.tipoImposta = originale.tipoImposta
		fornitura.codFiscale2 = originale.codFiscale2
		fornitura.codIdentificativo2 = originale.codIdentificativo2
		fornitura.idOperazione = originale.idOperazione
		fornitura.stato = originale.stato
		fornitura.codEnteBeneficiario = originale.codEnteBeneficiario
		fornitura.importoAccredito = originale.importoAccredito
		fornitura.dataMandato = originale.dataMandato
		fornitura.progrMandato = originale.progrMandato
		fornitura.importoRecupero = originale.importoRecupero
		fornitura.periodoRipartizioneOrig = originale.periodoRipartizioneOrig
		fornitura.progrRipartizioneOrig = originale.progrRipartizioneOrig
		fornitura.dataBonificoOrig = originale.dataBonificoOrig
		fornitura.tipoRecupero = originale.tipoRecupero
		fornitura.desRecupero = originale.desRecupero
		fornitura.importoAnticipazione = originale.importoAnticipazione
		fornitura.cro = originale.cro
		fornitura.dataAccreditamento = originale.dataAccreditamento
		fornitura.dataRipartizioneOrig = originale.dataRipartizioneOrig
		fornitura.iban = originale.iban
		fornitura.sezioneContoTu = originale.sezioneContoTu
		fornitura.numeroContoTu = originale.numeroContoTu
		fornitura.codMovimento = originale.codMovimento
		fornitura.desMovimento = originale.desMovimento
		fornitura.dataStornoScarto = originale.dataStornoScarto
		fornitura.dataElaborazioneNuova = originale.dataElaborazioneNuova
		fornitura.progrElaborazioneNuova = originale.progrElaborazioneNuova
		fornitura.tipoOperazione = originale.tipoOperazione
		fornitura.dataOperazione = originale.dataOperazione
		fornitura.tipoTributo = originale.tipoTributo
		fornitura.descrizioneTitr = originale.descrizioneTitr

		fornitura.annoAcc = null
		fornitura.numeroAcc = null
		fornitura.numeroProvvisorio = null
		fornitura.dataProvvisorio = null

		fornitura.importoNetto = null
		fornitura.importoIfel = null
		fornitura.importoLordo = null

		return fornitura
	}

	///
	/// Verifica la fornitura prima si salvare
	///
	def verificaFornitura(FornituraAEDTO fornitura) {

		String message = ""
		Integer result = 0

		///
		/// Accertamento
		///
		if ((fornitura.annoAcc == null) && (fornitura.numeroAcc != null)) {
			message += "- Accertamento -> Anno non valido !\n"
		}

		if ((fornitura.annoAcc != null) && (fornitura.numeroAcc == null)) {
			message += "- Accertamento -> Numero non valido !\n"
		}
		if ((fornitura.annoAcc != null) && (fornitura.numeroAcc != null)) {

			Integer annoEsercizio = Calendar.getInstance().get(Calendar.YEAR) as Integer
			List<Integer> anniEsercizio = [fornitura.annoRif as Integer, annoEsercizio, annoEsercizio - 1]

			Short annoAcc = fornitura.annoAcc as Short
			Integer numeroAcc = fornitura.numeroAcc as Integer

			List<CfaAccTributi> accertamenti = CfaAccTributi.createCriteria().list() {
				'in'("esercizio", anniEsercizio)
				eq("annoAcc", annoAcc)
				eq("numeroAcc", numeroAcc)
			}
			if (accertamenti.size() < 1) {
				///		message += "- Nessun Accertamento trovato corrispondente ai dati indicati !\n"
			}
			if (accertamenti.size() > 1) {
				///		message += "- Esiste piu\' di un Accertamento corrispondente ai dati indicati !\n"
			}
		}

		///
		/// Provvisorio
		///
		if ((fornitura.numeroProvvisorio == null) && (fornitura.dataProvvisorio != null)) {
			message += "- Provvisorio -> Numero non valido !\n"
		}

		if ((fornitura.numeroProvvisorio != null) && (fornitura.dataProvvisorio == null)) {
			message += "- Provvisorio -> Data non valida !\n"
		}
		if ((fornitura.numeroProvvisorio != null) && (fornitura.dataProvvisorio != null)) {

			Short esercizio = 0 as Short
			String numeroProvv = fornitura.numeroProvvisorio as String
			Date dataProvv = fornitura.dataProvvisorio as Date

			List<CfaProvvisorioEntrataTributi> provvisori = CfaProvvisorioEntrataTributi.createCriteria().list() {
				eq("numeroProvvisorio", numeroProvv)
				eq("dataProvvisorio", dataProvv)
			}
			if (provvisori.size() < 1) {
				message += "- Nessun Provvisorio trovato corrispondente ai dati indicati !\n"
			}
			if (provvisori.size() > 1) {
				message += "- Esiste piu\' di un Provvisorio corrispondente ai dati indicati !\n"
			}
		}

		///
		/// Importi
		///
		double importoNetto = fornitura.importoNetto ?: 0.0
		double importoIfel = fornitura.importoIfel ?: 0.0
		double importoLordo = fornitura.importoLordo ?: 0.0

		if ((importoNetto < 0.0) || (importoNetto > 999999999.99)) {
			message += "- Importi -> Netto non valido : indicare un numero tra 0.00 e 999999999.99, oppure lasciare vuoto\n"
		}
		if ((importoIfel < 0.0) || (importoIfel > 999999999.99)) {
			message += "- Importi -> IFEL non valido : indicare un numero tra 0.00 e 999999999.99, oppure lasciare vuoto\n"
		}
		if ((importoLordo < 0.0) || (importoLordo > 999999999.99)) {
			message += "- Importi -> Lordo non valido : indicare un numero tra 0.00 e 999999999.99, oppure lasciare vuoto\n"
		}

		///
		/// *** Fine
		///
		if (message.size() > 0) result = 1

		return [result: result, message: message]
	}

	///
	/// Salva modifiche a fornitura
	///
	def salvaFornitura(FornituraAEDTO fornituraDTO) {

		String message = ''
		Integer result = 0

		try {
			FornituraAE fornituraSalva = fornituraDTO.getDomainObject()
			if (fornituraSalva == null) {

				fornituraSalva = new FornituraAE()

				fornituraSalva.documentoCaricato = DocumentoCaricato.get(fornituraDTO.documentoCaricato.id)
				fornituraSalva.progressivo = getNuovoProgressivoFornitura(fornituraSalva)

				fornituraSalva.tipoRecord = fornituraDTO.tipoRecord
				fornituraSalva.dataFornitura = fornituraDTO.dataFornitura
				fornituraSalva.progrFornitura = fornituraDTO.progrFornitura

				fornituraSalva.dataRipartizione = fornituraDTO.dataRipartizione
				fornituraSalva.progrRipartizione = fornituraDTO.progrRipartizione
				fornituraSalva.dataBonifico = fornituraDTO.dataBonifico
				fornituraSalva.progrDelega = fornituraDTO.progrDelega
				fornituraSalva.progrRiga = fornituraDTO.progrRiga
				fornituraSalva.codEnte = fornituraDTO.codEnte
				fornituraSalva.tipoEnte = fornituraDTO.tipoEnte
				fornituraSalva.cab = fornituraDTO.cab
				fornituraSalva.codFiscale = fornituraDTO.codFiscale
				fornituraSalva.flagErrCodFiscale = fornituraDTO.flagErrCodFiscale
				fornituraSalva.dataRiscossione = fornituraDTO.dataRiscossione
				fornituraSalva.codEnteComunale = fornituraDTO.codEnteComunale
				fornituraSalva.codTributo = fornituraDTO.codTributo
				fornituraSalva.flagErrCodTributo = fornituraDTO.flagErrCodTributo
				fornituraSalva.rateazione = fornituraDTO.rateazione
				fornituraSalva.annoRif = fornituraDTO.annoRif
				fornituraSalva.flagErrAnno = fornituraDTO.flagErrAnno
				fornituraSalva.codValuta = fornituraDTO.codValuta
				fornituraSalva.importoDebito = fornituraDTO.importoDebito
				fornituraSalva.importoCredito = fornituraDTO.importoCredito
				fornituraSalva.ravvedimento = fornituraDTO.ravvedimento
				fornituraSalva.immobiliVariati = fornituraDTO.immobiliVariati
				fornituraSalva.acconto = fornituraDTO.acconto
				fornituraSalva.saldo = fornituraDTO.saldo
				fornituraSalva.numFabbricati = fornituraDTO.numFabbricati
				fornituraSalva.flagErrDati = fornituraDTO.flagErrDati
				fornituraSalva.detrazione = fornituraDTO.detrazione
				fornituraSalva.cognomeDenominazione = fornituraDTO.cognomeDenominazione
				fornituraSalva.codFiscaleOrig = fornituraDTO.codFiscaleOrig
				fornituraSalva.nome = fornituraDTO.nome
				fornituraSalva.sesso = fornituraDTO.sesso
				fornituraSalva.dataNas = fornituraDTO.dataNas
				fornituraSalva.comuneStato = fornituraDTO.comuneStato
				fornituraSalva.provincia = fornituraDTO.provincia
				fornituraSalva.tipoImposta = fornituraDTO.tipoImposta
				fornituraSalva.codFiscale2 = fornituraDTO.codFiscale2
				fornituraSalva.codIdentificativo2 = fornituraDTO.codIdentificativo2
				fornituraSalva.idOperazione = fornituraDTO.idOperazione
				fornituraSalva.stato = fornituraDTO.stato
				fornituraSalva.codEnteBeneficiario = fornituraDTO.codEnteBeneficiario
				fornituraSalva.importoAccredito = fornituraDTO.importoAccredito
				fornituraSalva.dataMandato = fornituraDTO.dataMandato
				fornituraSalva.progrMandato = fornituraDTO.progrMandato
				fornituraSalva.importoRecupero = fornituraDTO.importoRecupero
				fornituraSalva.periodoRipartizioneOrig = fornituraDTO.periodoRipartizioneOrig
				fornituraSalva.progrRipartizioneOrig = fornituraDTO.progrRipartizioneOrig
				fornituraSalva.dataBonificoOrig = fornituraDTO.dataBonificoOrig
				fornituraSalva.tipoRecupero = fornituraDTO.tipoRecupero
				fornituraSalva.desRecupero = fornituraDTO.desRecupero
				fornituraSalva.importoAnticipazione = fornituraDTO.importoAnticipazione
				fornituraSalva.cro = fornituraDTO.cro
				fornituraSalva.dataAccreditamento = fornituraDTO.dataAccreditamento
				fornituraSalva.dataRipartizioneOrig = fornituraDTO.dataRipartizioneOrig
				fornituraSalva.iban = fornituraDTO.iban
				fornituraSalva.sezioneContoTu = fornituraDTO.sezioneContoTu
				fornituraSalva.numeroContoTu = fornituraDTO.numeroContoTu
				fornituraSalva.codMovimento = fornituraDTO.codMovimento
				fornituraSalva.desMovimento = fornituraDTO.desMovimento
				fornituraSalva.dataStornoScarto = fornituraDTO.dataStornoScarto
				fornituraSalva.dataElaborazioneNuova = fornituraDTO.dataElaborazioneNuova
				fornituraSalva.progrElaborazioneNuova = fornituraDTO.progrElaborazioneNuova
				fornituraSalva.tipoOperazione = fornituraDTO.tipoOperazione
				fornituraSalva.dataOperazione = fornituraDTO.dataOperazione
				fornituraSalva.tipoTributo = fornituraDTO.tipoTributo
				fornituraSalva.descrizioneTitr = fornituraDTO.descrizioneTitr
			}

			fornituraSalva.annoAcc = fornituraDTO.annoAcc
			fornituraSalva.numeroAcc = fornituraDTO.numeroAcc
			fornituraSalva.numeroProvvisorio = fornituraDTO.numeroProvvisorio
			fornituraSalva.dataProvvisorio = fornituraDTO.dataProvvisorio

			fornituraSalva.importoNetto = fornituraDTO.importoNetto
			fornituraSalva.importoIfel = fornituraDTO.importoIfel
			fornituraSalva.importoLordo = fornituraDTO.importoLordo

			fornituraSalva.save(flush: true, failOnError: true)
		}
		catch (Exception e) {

			if (e?.message?.startsWith("ORA-20999")) {
				message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
				if (result < 1) result = 1
			} else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
				message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
				if (result < 1) result = 1
			} else {
				message += e.message
				if (result < 2) result = 2
			}
		}

		return [result: result, message: message]
	}

	///
	/// Aggiorna valore importi IFEL della fornitura
	///
	def salvaIFELFornitura(FornituraAEDTO fornituraDTO) {

		String message = ''
		Integer result = 0

		try {
			FornituraAE fornituraSalva = fornituraDTO.getDomainObject()

			if (fornituraSalva == null) {
				throw new Exception("FornituraAE non trovata !")
			}
			if (fornituraSalva.tipoRecord != 'R2') {
				throw new Exception("FornituraAE con tipo record non valido !")
			}

			fornituraSalva.importoIfel = fornituraDTO.importoIfel

			fornituraSalva.save(flush: true, failOnError: true)
		}
		catch (Exception e) {

			if (e?.message?.startsWith("ORA-20999")) {
				message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
				if (result < 1) result = 1
			} else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
				message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
				if (result < 1) result = 1
			} else {
				message += e.message
				if (result < 2) result = 2
			}
		}

		return [result: result, message: message]
	}

	///
	/// Elimina la fornitura
	///
	def eliminaFornitura(FornituraAEDTO fornituraDTO) {

		String message = ''
		Integer result = 0

		FornituraAE fornituraSalva = fornituraDTO.getDomainObject()
		if (fornituraSalva == null) {

			message = "Fornitura non registrata in banca dati !"
			result = 2
		} else {

			try {
				fornituraSalva.delete(flush: true)
			}
			catch (Exception e) {

				if (e?.message?.startsWith("ORA-20999")) {
					message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
					if (result < 1) result = 1
				} else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
					message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
					if (result < 1) result = 1
				} else {
					message += e.message
					if (result < 2) result = 2
				}
			}
		}

		return [result: result, message: message]
	}

	///
	/// *** Ricava nuovo numero sequenza
	///
	def getNuovoProgressivoFornitura(FornituraAE fornitura) {

		Integer progressivo = 1

		Sql sql = new Sql(dataSource)
		sql.call('{call FORNITURE_AE_NR(?, ?)}',
				[
						fornitura.documentoCaricato.id,
						Sql.NUMERIC
				],
				{ progressivo = it }
		)

		return progressivo
	}

	///
	/// Ricava lista anni validi in base a fornitura ed eventuale esercisio
	///
	def getListaAnniAcc(FornituraAEDTO fornitura, def esercizioOverride, Boolean addIfNotInList) {

		def listaAnniAcc = []

		Integer annoEsercizio

		if (esercizioOverride) {
			annoEsercizio = esercizioOverride as Integer
		} else {
			annoEsercizio = fornitura.annoRif as Integer
		}

		def elencoAnniAcc = CfaAccTributi.createCriteria().listDistinct() {
			projections {
				groupProperty("annoAcc")
			}
			eq("esercizio", annoEsercizio)
			gt("disponibilita", 0.0 as BigDecimal)
			order("annoAcc", "asc")
		}
		listaAnniAcc = [null] + elencoAnniAcc

		if (addIfNotInList != false) {
			Short annoAcc = fornitura.annoAcc
			if (annoAcc) {
				if (listaAnniAcc.find { it == annoAcc } == null) {
					listaAnniAcc << annoAcc
				}
			}
		}

		return listaAnniAcc
	}

	///
	/// Ricava lista numeri accertamento validi in base a fornitura ed eventuale esercisio
	///
	def getListaNumeriAcc(FornituraAEDTO fornitura, def esercizioOverride, Short annoAcc, Boolean addIfNotInList) {

		def listaNumeriAcc = []

		Integer annoEsercizio

		if (esercizioOverride) {
			annoEsercizio = esercizioOverride as Integer
		} else {
			annoEsercizio = fornitura.annoRif as Integer
		}

		def elencoNumeriAcc = CfaAccTributi.createCriteria().listDistinct() {
			eq("esercizio", annoEsercizio)
			eq("annoAcc", annoAcc)
			order("numeroAcc", "asc")
		}?.toDTO()

		listaNumeriAcc = []

		CfaAccTributiDTO accTributi = new CfaAccTributiDTO()
		accTributi.numeroAcc = 0
		listaNumeriAcc << accTributi

		elencoNumeriAcc.each {
			listaNumeriAcc << it
		}

		if (addIfNotInList) {
			def numeroAcc = fornitura.numeroAcc
			if (numeroAcc) {
				def accTributo = listaNumeriAcc.find { it.numeroAcc == numeroAcc }
				if (accTributo == null) {
					accTributi = new CfaAccTributiDTO()

					accTributi.esercizio = annoEsercizio
					accTributi.annoAcc = annoAcc
					accTributi.numeroAcc = numeroAcc
					accTributi.descrizioneAcc = ""

					listaNumeriAcc << accTributi
				}
			}
		}

		return listaNumeriAcc
	}

	///
	/// Ricava lista provvisori
	///
	def getListaProvvisori(FornituraAEDTO fornitura) {

		List<CfaProvvisorioEntrataTributiDTO> listaProvvisori = []

		def elecnoProvvisori = CfaProvvisorioEntrataTributi.createCriteria().list() {
			ne("esercizio", 0 as Short)
			order("esercizio", "asc")
			order("numeroProvvisorio", "asc")
			order("dataProvvisorio", "asc")
		}?.toDTO()

		CfaProvvisorioEntrataTributiDTO provvisorio = new CfaProvvisorioEntrataTributiDTO()
		provvisorio.esercizio = 0
		provvisorio.numeroProvvisorio = null
		provvisorio.dataProvvisorio = null
		listaProvvisori << provvisorio

		elecnoProvvisori.each {
			listaProvvisori << it
		}

		return listaProvvisori
	}

	///
	/// *** Associa provvisorio a forniture
	///
	def associaContabilita(Integer progDoc, List<Integer> listForniture, CfaAccTributiDTO accertamento, Boolean togliAcceTributo,
						   CfaProvvisorioEntrataTributiDTO provvisorio, Boolean togliProvvosorio) {

		def result = 0
		def message = ""

		try {
			listForniture.each { progressivo ->

				FornituraAE fornitura = FornituraAE.createCriteria().get {
					eq('documentoCaricato.id', progDoc as Long)
					eq('progressivo', progressivo as Integer)
				}

				if (fornitura == null) {
					throw new Exception("Documento : " + progDoc + ", Progressivo : " + progressivo + " -> Non trovato !")
				}

				if (accertamento != null) {
					fornitura.annoAcc = accertamento.annoAcc
					fornitura.numeroAcc = accertamento.numeroAcc
				}
				if (togliAcceTributo != false) {
					fornitura.annoAcc = null
					fornitura.numeroAcc = null
				}
				if (provvisorio != null) {
					fornitura.numeroProvvisorio = provvisorio.numeroProvvisorio
					fornitura.dataProvvisorio = provvisorio.dataProvvisorio
				}
				if (togliProvvosorio != false) {
					fornitura.numeroProvvisorio = null
					fornitura.dataProvvisorio = null
				}

				fornitura.save(flush: true, failOnError: true)
			}
		}
		catch (Exception e) {

			if (e?.message?.startsWith("ORA-20999")) {
				message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
				if (result < 1) result = 1
			} else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
				message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
				if (result < 1) result = 1
			} else {
				message += e.message
				if (result < 2) result = 2
			}
		}

		return [result: result, message: message]
	}

	///
	/// *** Controlla presenza riepilogo : 0 -> presente, 1 -> Non presente
	///
	def presenzaRiepilogoProvvisori(def ripartizione) {

		Integer result = 1

		try {
			Sql sql = new Sql(dataSource)

			sql.call('{? = call ELABORAZIONE_FORNITURE_AE.F_EXISTS_RIEPILOGO(?,?,?,?,?,?)}',
					[
							Sql.NUMERIC,
							ripartizione.documentoId,
							ripartizione.dataFornitura,
							ripartizione.progFornitura,
							ripartizione.dataRipartizione,
							ripartizione.progRipartizione,
							ripartizione.dataBonifico
					]
			)
					{ result = it }
		}
		catch (Exception e) {
            e.printStackTrace()
			commonService.serviceException(e)
        }

		return result
	}

	///
	/// *** Emette riepilogo provvisori, SOVRASCRIVE sempre
	///
	String eseguiEmissioneRiepilogoProvvisori(def ripartizione) {

		String result = ""

		try {
			Sql sql = new Sql(dataSource)

			sql.call('{? = call ELABORAZIONE_FORNITURE_AE.EMISSIONE_RIEPILOGO_PROVVISORI(?,?,?,?,?,?)}',
					[
							Sql.VARCHAR,
							ripartizione.documentoId,
							ripartizione.dataFornitura,
							ripartizione.progFornitura,
							ripartizione.dataRipartizione,
							ripartizione.progRipartizione,
							ripartizione.dataBonifico
					]
			)
					{ result = it }
		}
		catch (Exception e) {
            e.printStackTrace()
			commonService.serviceException(e)
        }

		return result
	}

	///
	/// *** Esegue quadratura versamenti
	///
	Short eseguiQuadraturaVersamenti(def ripartizione) {

		Short result = -1

		try {
			Sql sql = new Sql(dataSource)

			sql.call('{? = call ELABORAZIONE_FORNITURE_AE.QUADRATURA_VERSAMENTI(?,?,?,?,?,?)}',
					[
							Sql.NUMERIC,
							ripartizione.documentoId,
							ripartizione.dataFornitura,
							ripartizione.progFornitura,
							ripartizione.dataRipartizione,
							ripartizione.progRipartizione,
							ripartizione.dataBonifico
					]
			)
					{ result = it }
		}
		catch (Exception e) {
            e.printStackTrace()
			commonService.serviceException(e)
        }

		return result
    }

    def getComuneDaSiglaCFis(String siglaCFis) {

		def comune = null
		
		def listaComuni = Ad4Comune.createCriteria().list() {
			fetchMode("provincia", FetchMode.JOIN)
			fetchMode("stato", FetchMode.JOIN)

			ilike("siglaCodiceFiscale", siglaCFis)

			isNull('dataSoppressione')

			order("denominazione", "asc")
		}

		if(listaComuni.size() > 0) {
			comune = listaComuni[0]
		}
		
		return comune
    }

	def getDatiComuneDaSiglaCFis(String codice) {
	
		def datiEnte = [:]

		def comuni = Ad4Comune.createCriteria().list() {
			fetchMode("provincia", FetchMode.JOIN)
			fetchMode("stato", FetchMode.JOIN)

			ilike("siglaCodiceFiscale", codice)
			isNull('dataSoppressione')

			order("denominazione", "asc")
		}

		if(comuni.size() > 0) {
			def comune = comuni[0]
			datiEnte.siglaCFis = comune.siglaCodiceFiscale
			datiEnte.descrizione = comune.denominazione
		}
		else {
			datiEnte.siglaCFis = codice
			datiEnte.descrizione = 'Comune non trovato ('+ codice + ')'
		}

		return datiEnte
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
}
