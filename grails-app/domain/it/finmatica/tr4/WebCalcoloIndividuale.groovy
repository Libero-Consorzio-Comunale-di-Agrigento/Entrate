package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.so4.struttura.So4Amministrazione
import it.finmatica.tr4.pratiche.PraticaTributo;

class WebCalcoloIndividuale {

	Contribuente contribuente
	Date lastUpdated
	Date dateCreated
	Ad4Utente 				utente
	short anno
	TipoTributo tipoTributo
	PraticaTributo pratica
	String tipoCalcolo	
	BigDecimal totaleTerreniRidotti
	BigDecimal numeroFabbricati
	BigDecimal saldoDetrazioneStd
	
	static hasMany 		= [ webCalcoloDettagli: 	WebCalcoloDettaglio ]
	

	static mapping = {
		id					column: "id_calcolo_individuale", generator: "sequence" , params: [sequence: "wcin_sq"]
		contribuente		column: "cod_fiscale"
		tipoTributo			column: "tipo_tributo"
		pratica				column: "pratica"
		utente				column: "utente"
		lastUpdated			sqlType:'Date', column:'LAST_UPDATED'
		dateCreated			sqlType:'Date', column:'DATE_CREATED'
		webCalcoloDettagli 	cascade: "all-delete-orphan"
	}

	static constraints = {
		utente maxSize: 8
		numeroFabbricati nullable: true
		totaleTerreniRidotti nullable: true
		saldoDetrazioneStd nullable: true
	}
	
	def springSecurityService
	static transients = ['springSecurityService']
	
	def beforeValidate () {
		ente	  = ente?:springSecurityService.principal.amministrazione
		utente = springSecurityService.currentUser
		//webCalcoloDettagli*.beforeValidate()
	}
	
	def beforeInsert () {
		utente 	= springSecurityService.currentUser
	}
	
	def beforeUpdate () {
		utente = springSecurityService.currentUser
	}
	
}
