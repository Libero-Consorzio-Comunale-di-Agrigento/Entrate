package it.finmatica.tr4.datiesterni

import it.finmatica.ad4.autenticazione.Ad4Utente;
import it.finmatica.so4.struttura.So4Amministrazione;

class ParametroImport {
	
	String nomeParametro
	String labelParametro
	String componente
	
	String nomeBean
	String nomeMetodo
	
	Ad4Utente			utente
	
	Short				sequenza
	
	TitoloDocumento	titoloDocumento
	
    static constraints = {
		nomeParametro     nullable: true
		labelParametro    nullable: true
		componente        nullable: true
        sequenza		  nullable: true						 
		nomeBean          nullable: true
		nomeMetodo        nullable: true
    }
	
	static mapping = {
		id				column: "id_parametro_import"
		titoloDocumento	column: "id_titolo_documento"
		utente			column: "utente"
		
		table "web_parametri_import"
	}
	
	def springSecurityService
	static transients = ['springSecurityService']
	
	def beforeValidate () {
		utente	= springSecurityService.currentUser
	}
	
	def beforeInsert () {
		utente 	= springSecurityService.currentUser
	}
	
	def beforeUpdate () {
		utente = springSecurityService.currentUser
	}
	
}
