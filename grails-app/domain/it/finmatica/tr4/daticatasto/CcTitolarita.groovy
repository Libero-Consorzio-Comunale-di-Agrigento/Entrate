package it.finmatica.tr4.daticatasto

import it.finmatica.ad4.autenticazione.Ad4Utente;
import it.finmatica.so4.struttura.So4Amministrazione;

import java.util.Date;

class CcTitolarita {
	
	String	codiceAmministrativo
	String	sezione
	
	CcParticella	particella
	CcFabbricato	fabbricato
	CcSoggetto		soggetto
	
	CcCodiceDiritto	codiceDiritto
	String			titoloNonCodificato
	
	Long			quotaNumeratore
	Long			quotaDenominatore
	
	String			regime
	Integer			idSoggettoRiferimento
	
	Date			dataValiditaDal
	Date			dataRegAttiDal
	String 			tipoNotaDal
	String			numeroNotaDal
	String			progrNotaDal
	Short			annoNotaDal
	
	String			partita
	
	Date			dataValiditaAl
	Date			dataRegAttiAl
	String 			tipoNotaAl
	String			numeroNotaAl
	String			progrNotaAl
	Short			annoNotaAl
	
	Integer			idMutazioneIniziale
	Integer			idMutazioneFinale
	Integer			identificativoTitolarita
	
	String			codiceCausaleAttoGen
	String			descrizioneAttoGen
	
	String			codiceCausaleAttoCon
	String			descrizioneAttoCon
	
	Ad4Utente			utente
	
	static mapping = {
		id				column: "id_titolarita"
		particella 		column: "id_particella"
		fabbricato		column: "id_fabbricato"
		soggetto		column: "id_soggetto"
		codiceDiritto 	column: "id_codice_diritto"
		
		
		dataValiditaDal	sqlType: 'Date'
		dataValiditaAl	sqlType: 'Date'
		dataRegAttiDal  sqlType: 'Date'
		dataRegAttiAl   sqlType: 'Date'
		
		utente			column: "utente"
		
		table "web_cc_titolarita"
	}
	
	static constraints = {
		particella			  nullable: true
		fabbricato			  nullable: true
		codiceDiritto         nullable: true
		titoloNonCodificato   nullable: true
							  
		quotaNumeratore       nullable: true
		quotaDenominatore     nullable: true
							  
		regime                nullable: true
		idSoggettoRiferimento   nullable: true
							  
		dataValiditaDal       nullable: true
		dataRegAttiDal        nullable: true
		tipoNotaDal           nullable: true
		numeroNotaDal         nullable: true
		progrNotaDal          nullable: true
		annoNotaDal           nullable: true
							  nullable: true
		partita               nullable: true
							  
		dataValiditaAl        nullable: true
		dataRegAttiAl         nullable: true
		tipoNotaAl            nullable: true
		numeroNotaAl          nullable: true
		progrNotaAl           nullable: true
		annoNotaAl            nullable: true
							  
		idMutazioneIniziale   nullable: true
		idMutazioneFinale     nullable: true
		identificativoTitolarita	nullable: true
							  
		codiceCausaleAttoGen  nullable: true
		descrizioneAttoGen    nullable: true
							  
		codiceCausaleAttoCon  nullable: true
		descrizioneAttoCon    nullable: true
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
