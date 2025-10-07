package it.finmatica.tr4.pratiche

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.Fonte
import it.finmatica.tr4.tipi.SiNoType

class DenunciaIci {
	PraticaTributo			pratica
	Fonte 					fonte
	
	long denuncia
	String prefissoTelefonico
	Integer numTelefonico
	boolean flagCf
	boolean flagFirma
	boolean flagDenunciante
	Integer progrAnci
	
	Ad4Utente	utente
	Date lastUpdated
	String note

	static mapping = {
		id 		column: "pratica", generator: "assigned"
		pratica	column: "pratica", updateable: false, insertable: false
		
		fonte 	column: "fonte"
		utente	column: "utente"
		
		flagCf			type: SiNoType//, sqlType: 'varchar2'
		flagFirma		type: SiNoType//, sqlType: 'varchar2'
		flagDenunciante	type: SiNoType//, sqlType: 'varchar2'
		
		lastUpdated column: "data_variazione", sqlType: 'Date'
		
		table 'denunce_ici'
		version false
	}

	static constraints = {
		prefissoTelefonico nullable: true, maxSize: 4
		numTelefonico nullable: true
		flagCf nullable: true, maxSize: 1
		flagFirma nullable: true, maxSize: 1
		flagDenunciante nullable: true, maxSize: 1
		progrAnci nullable: true
		utente maxSize: 8
		note nullable: true, maxSize: 2000
		lastUpdated		nullable: true
	}
	
	def springSecurityService
	static transients = ['springSecurityService']
	
	def beforeValidate () {
		utente = springSecurityService.currentUser
	}
	
	def beforeInsert () {
		utente = springSecurityService.currentUser
	}
	
	def beforeUpdate () {
		utente = springSecurityService.currentUser
	}
}
