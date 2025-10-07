package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente

class SuccessioniDefunti {

	String ufficio
	Short anno
	Integer volume
	Integer numero
	Short sottonumero
	String comune
	String tipoDichiarazione
	Date dataApertura
	String codFiscale
	String cognome
	String nome
	String sesso
	String cittaNas
	String provNas
	Date dataNas
	String cittaRes
	String provRes
	String indirizzo
	String statoSuccessione
	Ad4Utente	utente
	Date lastUpdated
	String note
	Long pratica

	static mapping = {
		id column: "successione", generator: "assigned"
		utente		column: "utente"
		version false
		dataApertura	sqlType:'Date', column:'data_apertura'
		dataNas			sqlType:'Date', column:'data_nas'
		lastUpdated	sqlType:'Date', column:'data_variazione'
	}

	static constraints = {
		ufficio maxSize: 3
		comune maxSize: 4
		tipoDichiarazione maxSize: 1
		dataApertura nullable: true
		codFiscale nullable: true, maxSize: 16
		cognome nullable: true, maxSize: 25
		nome nullable: true, maxSize: 25
		sesso nullable: true, maxSize: 1
		cittaNas nullable: true, maxSize: 30
		provNas nullable: true, maxSize: 2
		dataNas nullable: true
		cittaRes nullable: true, maxSize: 30
		provRes nullable: true, maxSize: 2
		indirizzo nullable: true, maxSize: 30
		statoSuccessione nullable: true, maxSize: 30
		utente maxSize: 8
		note nullable: true, maxSize: 2000
		pratica nullable: true
	}
}
