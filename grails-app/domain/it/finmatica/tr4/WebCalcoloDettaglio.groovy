package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.sportello.TipoOggettoCalcolo

class WebCalcoloDettaglio {

	Date lastUpdated
	Date dateCreated
	Ad4Utente utente
	int ordinamento
	Integer numFabbricati
	TipoOggettoCalcolo	tipoOggetto
	BigDecimal	versAcconto
	BigDecimal	versAccontoErar
	BigDecimal	acconto
	BigDecimal	accontoErar
	BigDecimal	saldo
	BigDecimal	saldoErar
	
	static belongsTo = [calcoloIndividuale: WebCalcoloIndividuale]
	
	static mapping = {
		id					column: "id_calcolo_dettagli", generator: "sequence" , params: [sequence: "wcde_sq"]
		calcoloIndividuale	column: "id_calcolo_individuale"
		utente column: "utente", ignoreNotFound: true
		lastUpdated			sqlType:'Date', column:'LAST_UPDATED'
		dateCreated			sqlType:'Date', column:'DATE_CREATED'
		
		table 'web_calcolo_dettagli'
	}

	static constraints = {
		utente 			maxSize: 8
		tipoOggetto		maxSize: 25
		numFabbricati 	nullable: true
		versAcconto		nullable: true
		versAccontoErar nullable: true
		acconto 		nullable: true
		accontoErar 	nullable: true
		saldo 			nullable: true
		saldoErar 		nullable: true
	}
	
	def springSecurityService
	static transients = ['springSecurityService']
	
}
