package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.so4.struttura.So4Amministrazione

class ArchivioVie {

	String 					denomUff
	String 					denomOrd
	Ad4Utente				utente
	Date 					lastUpdated
	String 					note
	
	static hasMany = [denominazioniVia: DenominazioneVia]

	static mapping = {
		id 		column: "cod_via", generator: "assigned"
		lastUpdated	column: "data_variazione", sqlType: 'Date'
		utente	column: "utente"
		version false
	}

	static constraints = {
		denomUff 	nullable: true, maxSize: 60
		denomOrd 	nullable: true, maxSize: 60
		utente 		nullable: true, maxSize: 8
		note 		nullable: true, maxSize: 2000
	}
	
	def springSecurityService
	static transients = ['springSecurityService']
	
	
}
