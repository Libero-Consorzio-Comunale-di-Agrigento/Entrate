package it.finmatica.tr4.daticatasto

import it.finmatica.ad4.autenticazione.Ad4Utente;
import it.finmatica.so4.struttura.So4Amministrazione;

import java.util.Date;

class CcSoggetto {
	// chiave
	String	codiceAmministrativo
	String	sezione
	Integer	identificativoSoggetto
	String	tipoSoggetto
	
    String	cognome
	String	nome
	String	sesso
	Date	dataNascita
	String	luogoNascita
	String	codiceFiscale
	String	indicazioniSupplementari
	String	denominazione
	String	sede
	
	Ad4Utente			utente
	
	static hasMany = [ titolarita : CcTitolarita ]
	
	static mapping = {
		id		column: "id_soggetto"
		utente	column: "utente"
		
		dataNascita	sqlType: 'Date'
		
		table "web_cc_soggetti"
	}
	
	static constraints = {
		cognome						nullable: true
		nome                        nullable: true
		sesso                       nullable: true
		dataNascita                 nullable: true
		luogoNascita                nullable: true
		codiceFiscale               nullable: true
		indicazioniSupplementari    nullable: true
		denominazione               nullable: true
		sede                        nullable: true
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
