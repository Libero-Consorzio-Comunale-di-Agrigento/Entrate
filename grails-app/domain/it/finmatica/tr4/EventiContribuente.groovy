package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class EventiContribuente implements Serializable {

	String codFiscale
	String tipoEvento
	Short sequenza
	String flagAutomatico
	Ad4Utente	utente
	Date lastUpdated
	String note

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codFiscale
		builder.append tipoEvento
		builder.append sequenza
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codFiscale, other.codFiscale
		builder.append tipoEvento, other.tipoEvento
		builder.append sequenza, other.sequenza
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codFiscale", "tipoEvento", "sequenza"]
		lastUpdated column: "data_variazione", sqlType: 'Date'
		utente column: "utente", ignoreNotFound: true
		version false
	}

	static constraints = {
		codFiscale maxSize: 16
		tipoEvento maxSize: 1
		flagAutomatico nullable: true, maxSize: 1
		utente nullable: true, maxSize: 8
		lastUpdated nullable: true
		note nullable: true, maxSize: 2000
	}
}
