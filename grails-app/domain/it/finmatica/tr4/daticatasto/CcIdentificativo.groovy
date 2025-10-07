package it.finmatica.tr4.daticatasto

import it.finmatica.ad4.autenticazione.Ad4Utente;
import it.finmatica.so4.struttura.So4Amministrazione;

class CcIdentificativo {
	
	String	sezioneUrbana
	String	foglio
	String	numero
	Short	denominatore
	String	subalterno
	String	edificialita
	
	Ad4Utente			utente
	
	static belongsTo = [fabbricato: CcFabbricato]
	
	static mapping = {
		id			column: "id_identificativo"
		utente		column: "utente"
		fabbricato	column: "id_fabbricato"
		
		table "web_cc_identificativi"
	}
	
    static constraints = {
		sezioneUrbana    nullable: true
		foglio           nullable: true
		numero           nullable: true
		denominatore     nullable: true
		subalterno       nullable: true
		edificialita     nullable: true
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
