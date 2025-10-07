package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class DenunceIcp implements Serializable {

	Long pratica
	Ad4Utente	utente
	Date lastUpdated
	String note

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append pratica
		builder.append utente
		builder.append lastUpdated
		builder.append note
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append pratica, other.pratica
		builder.append utente, other.utente
		builder.append lastUpdated, other.lastUpdated
		builder.append note, other.note
		builder.isEquals()
	}

	static mapping = {
		id composite: ["pratica", "utente", "lastUpdated", "note"]
		lastUpdated column: "data_variazione", sqlType: 'Date'
		utente	column: "utente"
		version false
	}

	static constraints = {
		utente maxSize: 8
		note nullable: true, maxSize: 2000
	}
}
