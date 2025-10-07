package it.finmatica.tr4


import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.ad4.dizionari.Ad4ComuneTr4

class RecapitoSoggetto implements Serializable {

	TipoTributo		tipoTributo
	TipoRecapito	tipoRecapito
	String 			descrizione
	ArchivioVie 	archivioVie
	Integer 		numCiv
	String 			suffisso
	String 			scala
	String 			piano
	Short 			interno
	Date 			dal
	Date 			al
	Ad4Utente 		utente
	Date 			lastUpdated
	String 			note
	Ad4ComuneTr4	comuneRecapito
	Integer 		cap
	String 			zipcode
	String 			presso
	Soggetto		soggetto
	//static belongsTo = [soggetto: Soggetto]
	
	static mapping = {
		id column: "id_recapito", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "RECAPITI_SOGGETTO_NR"]
		
		tipoTributo		column: "tipo_tributo"
		tipoRecapito	column: "tipo_recapito"
		utente column: "utente", ignoreNotFound: true
		soggetto		column: "ni"
		archivioVie		column: "cod_via"
		
		lastUpdated		column: "data_variazione", sqlType: "Date"
		dal				sqlType: "Date"
		al				sqlType: "Date"
		columns {
			comuneRecapito {
				column name: "cod_com"
				column name: "cod_pro"
			}
		}
		table "recapiti_soggetto"
		version false
	}

	static constraints = {
		tipoTributo nullable: true, maxSize: 5
		descrizione nullable: true, maxSize: 60
		archivioVie nullable: true
		numCiv nullable: true
		suffisso nullable: true, maxSize: 10
		scala nullable: true, maxSize: 5
		piano nullable: true, maxSize: 5
		interno nullable: true
		dal nullable: true
		al nullable: true
		utente maxSize: 8
		note nullable: true, maxSize: 2000
		comuneRecapito nullable: true
		cap nullable: true
		zipcode nullable: true, maxSize: 10
		presso nullable: true, maxSize: 60
		lastUpdated nullable: true
	}
	
	def springSecurityService
	static transients = ['springSecurityService']
	
	def beforeValidate () {
		utente	= springSecurityService.currentUser
	}
	
	def beforeInsert () {
		utente	= springSecurityService.currentUser
	}
}
