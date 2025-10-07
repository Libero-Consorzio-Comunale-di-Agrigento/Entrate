package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente

class DenunceIciap {

	Byte numUip
	String desProf
	String codAttivita
	String flagAlbo
	BigDecimal locale
	BigDecimal coperta
	BigDecimal scoperta
	BigDecimal superficie
	BigDecimal riduzione
	BigDecimal consistenza
	Byte settore
	BigDecimal reddito
	String redditoZero
	Boolean coeffReddito
	Date dataCompilazione
	String flagCf
	String flagFirma
	String flagDenunciante
	String flagSettore
	String flagStagionale
	String flagVersamento
	Date dataIntegrazione
	BigDecimal importoIntegrazione
	Ad4Utente	utente
	Date lastUpdated
	String note

	static mapping = {
		id column: "PRATICA", generator: "assigned"
		dataCompilazione sqlType: 'Date'
		dataIntegrazione sqlType: 'Date'
		lastUpdated column: "data_variazione", sqlType: 'Date'
		utente	column: "utente"
		version false
	}

	static constraints = {
		numUip nullable: true
		desProf nullable: true, maxSize: 60
		codAttivita nullable: true, maxSize: 5
		flagAlbo nullable: true, maxSize: 1
		locale nullable: true
		coperta nullable: true
		scoperta nullable: true
		superficie nullable: true
		riduzione nullable: true
		consistenza nullable: true
		settore nullable: true
		reddito nullable: true
		redditoZero nullable: true, maxSize: 1
		coeffReddito nullable: true
		dataCompilazione nullable: true
		flagCf nullable: true, maxSize: 1
		flagFirma nullable: true, maxSize: 1
		flagDenunciante nullable: true, maxSize: 1
		flagSettore nullable: true, maxSize: 1
		flagStagionale nullable: true, maxSize: 1
		flagVersamento nullable: true, maxSize: 1
		dataIntegrazione nullable: true
		importoIntegrazione nullable: true
		utente maxSize: 8
		note nullable: true, maxSize: 2000
	}
}
