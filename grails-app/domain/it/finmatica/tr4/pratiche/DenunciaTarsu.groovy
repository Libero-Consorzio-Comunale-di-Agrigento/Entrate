package it.finmatica.tr4.pratiche

import it.finmatica.ad4.autenticazione.Ad4Utente

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class DenunciaTarsu implements Serializable {

	PraticaTributo 	pratica
	Ad4Utente		utente
	Date 			lastUpdated
	String 			note

	static mapping = {
		id 		column: "pratica", generator: "assigned"
		pratica	column: "pratica", updateable: false, insertable: false
		
		lastUpdated column: "data_variazione", sqlType: 'Date'
		utente	column: "utente"
		
		table "denunce_tarsu"
		version false
	}

	static constraints = {
		utente maxSize: 8
		note nullable: true, maxSize: 2000
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
