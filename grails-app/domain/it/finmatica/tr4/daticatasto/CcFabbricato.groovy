package it.finmatica.tr4.daticatasto

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.so4.struttura.So4Amministrazione

class CcFabbricato {
	// chiave
	String	codiceAmministrativo
	String	sezione
	Integer	idImmobile
	String	tipoImmobile
	Integer	progressivo
    
	String	zona
	String	categoria
	String	classe
	
	BigDecimal	consistenza
	BigDecimal	superficie
	BigDecimal	renditaLire
	BigDecimal	renditaEuro
	
	String		lotto
	String		edificio
	String		scala
	String		interno1
	String		interno2
	String		piano1
	String		piano2
	String		piano3
	String		piano4
	
	Date		dataEfficiaciaInizio
	Date		dataRegAttiInizio
	String 		tipoNotaInizio
	String		numeroNotaInizio
	String		progrNotaInizio
	Short		annoNotaInizio
	
	Date		dataEfficiaciaFine
	Date		dataRegAttiFine
	String 		tipoNotaFine
	String		numeroNotaFine
	String		progrNotaFine
	Short		annoNotaFine
	
	String		partita
	String		annotazione
	
	Integer		idMutazioneIniziale
	Integer		idMutazioneFinale
	
	String		protocolloNotifica
	Date		dataNotifica
	
	Ad4Utente			utente
	
	static mapping = {
		id 		column: "id_fabbricato"
		utente	column: "utente"
		
		dataEfficiaciaInizio	sqlType: 'Date'
		dataRegAttiInizio       sqlType: 'Date'
		dataEfficiaciaFine      sqlType: 'Date'
		dataRegAttiFine         sqlType: 'Date'
		dataNotifica			sqlType: 'Date'
		
		table "web_cc_fabbricati"
	}
	
	static hasMany = [	
				identificativi	: CcIdentificativo
			,	indirizzi		: CcIndirizzo
			,	titolarita		: CcTitolarita	]	
	
	static constraints = {
		sezione					nullable: true
		annoNotaFine 			nullable: true
		annoNotaInizio			nullable: true
		idMutazioneFinale		nullable: true
		dataEfficiaciaInizio	nullable: true
		dataRegAttiInizio		nullable: true
		dataEfficiaciaFine		nullable: true
		dataRegAttiFine			nullable: true
		consistenza				nullable: true
		superficie				nullable: true
		renditaLire				nullable: true
		renditaEuro				nullable: true
		progressivo				nullable: true
		lotto                   nullable: true
		edificio                nullable: true
		scala                   nullable: true
		interno1                nullable: true
		interno2                nullable: true
		piano1                  nullable: true
		piano2                  nullable: true
		piano3                  nullable: true
        piano4                  nullable: true
		annotazione				nullable: true
		zona					nullable: true
		classe					nullable: true
		categoria				nullable: true
		tipoNotaInizio          nullable: true
		numeroNotaInizio        nullable: true
		progrNotaInizio         nullable: true
		annoNotaInizio          nullable: true
		tipoNotaFine            nullable: true
		numeroNotaFine          nullable: true
		progrNotaFine           nullable: true
		annoNotaFine            nullable: true
		partita                 nullable: true
		idMutazioneIniziale     nullable: true
		idMutazioneFinale       nullable: true
		protocolloNotifica      nullable: true
		dataNotifica            nullable: true
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
