package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class EredeSoggetto implements Serializable {

	Soggetto soggetto
	Soggetto soggettoErede
	Short numeroOrdine
	Ad4Utente	utente
	Date lastUpdated
	String note
	Soggetto soggettoEredeId

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append soggetto?.id
		builder.append soggettoErede.id
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append soggetto.id, other.soggetto.id
		builder.append soggettoErede.id, other.soggettoErede.id
		builder.isEquals()
	}

	static mapping = {
		id composite: ["soggetto", "soggettoErede"]
		
		soggetto	column: "ni"
		soggettoErede	column: "ni_erede"
		soggettoEredeId	column: "ni_erede", updateable: false, insertable: false
		lastUpdated column: "data_variazione", sqlType: 'Date'
		utente column: "utente", ignoreNotFound: true
		table "eredi_soggetto"
		version false
	}

	static constraints = {
		utente nullable: true, maxSize: 8
		lastUpdated nullable: true
		note nullable: true, maxSize: 2000
	}
	
	def springSecurityService
	static transients = ['springSecurityService']
	
	def beforeValidate () {
		utente	= springSecurityService.currentUser
	}
	
	def beforeInsert () {
		utente	= springSecurityService.currentUser
	}
	
}
