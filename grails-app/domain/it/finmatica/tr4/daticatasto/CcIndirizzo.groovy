package it.finmatica.tr4.daticatasto

import it.finmatica.ad4.autenticazione.Ad4Utente;
import it.finmatica.so4.struttura.So4Amministrazione;

class CcIndirizzo {
	
	CcToponimo	toponimo
	String	indirizzo
	String	civico1
	String	civico2
	String	civico3
	Short	codiceStrada
	
	Ad4Utente			utente
	
	static belongsTo = [fabbricato: CcFabbricato]
	
	static mapping = {
		id column: "id_indirizzo"
		utente	column: "utente"
		fabbricato column: "id_fabbricato"
		toponimo	column: "id_toponimo"
		table "web_cc_indirizzi"
	}
	
    static constraints = {
		toponimo       nullable: true
		indirizzo      nullable: true
		civico1        nullable: true
		civico2        nullable: true
		civico3        nullable: true
		codiceStrada   nullable: true
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
