package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente

class Fatture {

	BigDecimal fattura
	Short anno
	Integer numero
	String codFiscale
	Date dataEmissione
	Date dataScadenza
	String flagStampa
	BigDecimal importoTotale
	BigDecimal fatturaRif
	Short annoRif
	Integer numeroRif
	Ad4Utente	utente
	Date lastUpdated
	String note
	String flagDelega

	static mapping = {
		id name: "fattura", generator: "assigned"
		dataEmissione   sqlType: 'Date'
		dataScadenza  	sqlType: 'Date'
		lastUpdated  	column: "data_variazione", sqlType: 'Date'
		utente	column: "utente"
		version false
	}

	static constraints = {
		codFiscale nullable: true, maxSize: 16
		dataEmissione nullable: true
		dataScadenza nullable: true
		flagStampa nullable: true, maxSize: 1
		importoTotale nullable: true
		fatturaRif nullable: true
		annoRif nullable: true
		numeroRif nullable: true
		utente nullable: true, maxSize: 8
		lastUpdated nullable: true
		note nullable: true, maxSize: 2000
		flagDelega nullable: true, maxSize: 1
	}
}
