package it.finmatica.tr4.datiesterni

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.so4.struttura.So4Amministrazione;

import java.sql.Blob

class DocumentoCaricato {

	TitoloDocumento titoloDocumento
	String 			nomeDocumento
	byte[] 			contenuto
	Short 			stato
	Ad4Utente		utente
	Date 			lastUpdated
	String 			note

	static hasMany = [documentiCaricatiMulti: DocumentoCaricatoMulti]

	static mapping = {
		id column: "documento_id", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "DOCUMENTI_CARICATI_NR"]
		titoloDocumento column: "titolo_documento"
		contenuto	sqlType: 'Blob'
		utente	column: "utente"
		lastUpdated column: "data_variazione", sqlType: 'Date'
		table "documenti_caricati"
		version false
	}

	static constraints = {
		contenuto nullable: true
		utente maxSize: 8
		lastUpdated nullable: true
		note nullable: true, maxSize: 2000
		//cartellaDocMulti nullable: true
	}
	
	def springSecurityService
	static transients = ['springSecurityService']
	
	def beforeValidate () {
		utente 	= utente?:springSecurityService.currentUser
	}
	
	def beforeInsert () {
		utente 	= utente?:springSecurityService.currentUser
	}
	
	def beforeUpdate () {
		utente = utente?:springSecurityService.currentUser
	}
	
}
