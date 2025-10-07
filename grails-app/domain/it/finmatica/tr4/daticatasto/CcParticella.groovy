package it.finmatica.tr4.daticatasto

import it.finmatica.ad4.autenticazione.Ad4Utente;
import it.finmatica.so4.struttura.So4Amministrazione;

import java.util.Date;

class CcParticella {
	// chiave
	String	codiceAmministrativo
	String	sezione
	Integer	idImmobile
	String	tipoImmobile
	Integer	progressivo
    
	Integer	foglio
	String	numero
	Short	denominatore
	String	subalterno
	String	edificialita
	
	CodiceQualita	codiceQualita
	String	classe
	Integer	ettari
	Short	are
	Short	centiare
	
	Boolean	flagReddito
	Boolean	flagPorzione
	Boolean	flagDeduzioni
	
	BigDecimal	redditoDominicaleLire
	BigDecimal	redditoAgrarioLire
	BigDecimal	redditoDominicaleEuro
	BigDecimal	redditoAgrarioEuro
	
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
	
	Ad4Utente			utente
	
	static mapping = {
		id		column: "id_particella"
		utente	column: "utente"
		
		flagReddito		type: 'numeric_boolean'
		flagPorzione	type: 'numeric_boolean'
		flagDeduzioni	type: 'numeric_boolean'
		
		dataEfficiaciaInizio	sqlType: 'Date'
		dataRegAttiInizio       sqlType: 'Date'
		dataEfficiaciaFine      sqlType: 'Date'
		dataRegAttiFine         sqlType: 'Date'
		
		table "web_cc_particelle"
	}
	
	static hasMany = [ titolarita		: CcTitolarita ]
	
	static constraints = {
		progressivo		nullable: true
		foglio          nullable: true
		numero          nullable: true
		denominatore    nullable: true
		subalterno      nullable: true
		edificialita    nullable: true
		foglio          nullable: true
		numero          nullable: true
		denominatore    nullable: true
		subalterno      nullable: true
		edificialita    nullable: true
		                
		codiceQualita   nullable: true
		classe          nullable: true
		ettari          nullable: true
		are             nullable: true
		centiare        nullable: true
		flagReddito     nullable: true
		flagPorzione    nullable: true
		flagDeduzioni   nullable: true
		redditoDominicaleLire   nullable: true
		redditoAgrarioLire      nullable: true
		redditoDominicaleEuro   nullable: true
		redditoAgrarioEuro      nullable: true
		dataEfficiaciaInizio    nullable: true
		dataRegAttiInizio       nullable: true
		tipoNotaInizio          nullable: true
		numeroNotaInizio        nullable: true
		progrNotaInizio         nullable: true
		annoNotaInizio          nullable: true
		dataEfficiaciaFine      nullable: true
		dataRegAttiFine         nullable: true
		tipoNotaFine            nullable: true
		numeroNotaFine          nullable: true
		progrNotaFine           nullable: true
		annoNotaFine            nullable: true
	    partita                 nullable: true
	    annotazione             nullable: true
		idMutazioneIniziale     nullable: true
		idMutazioneFinale       nullable: true
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
