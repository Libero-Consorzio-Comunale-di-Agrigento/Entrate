package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Eventi implements Serializable {

	String tipoEvento
	Short sequenza
	Date dataEvento
	String descrizione
	String note

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tipoEvento
		builder.append sequenza
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tipoEvento, other.tipoEvento
		builder.append sequenza, other.sequenza
		builder.isEquals()
	}

	static mapping = {
		id composite: ["tipoEvento", "sequenza"]
		dataEvento sqlType: 'Date'
		version false
	}

	static constraints = {
		tipoEvento maxSize: 1
		dataEvento nullable: true
		descrizione nullable: true, maxSize: 60
		note nullable: true, maxSize: 2000
		sequenza nullable: true
	}
}
