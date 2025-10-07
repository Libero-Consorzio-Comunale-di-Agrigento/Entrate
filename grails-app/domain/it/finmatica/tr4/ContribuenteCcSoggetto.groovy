package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.ad4.dizionari.Ad4ComuneTr4
import it.finmatica.tr4.tipi.SiNoType
import it.finmatica.tr4.daticatasto.CcSoggetto

class ContribuenteCcSoggetto {

	Contribuente	contribuente 
	Long			id_soggetto
	Ad4Utente		utente
	String			note
	
	static mapping = {
		id				column: "id", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "CONTRIBUENTI_CC_SOGGETTI_NR"]
		
		contribuente 	column: "cod_fiscale"
		utente			column: "utente"
		
		table "contribuenti_cc_soggetti"
		
		version 	false
	}

	static constraints = {
		id_soggetto		nullable: false
		contribuente	nullable: false
		note			nullable: true
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
