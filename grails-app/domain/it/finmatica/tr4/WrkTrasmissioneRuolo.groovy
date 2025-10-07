package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class WrkTrasmissioneRuolo implements Serializable {

	BigDecimal ruolo
	BigDecimal progressivo
	String dati

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append ruolo
		builder.append progressivo
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append ruolo, other.ruolo
		builder.append progressivo, other.progressivo
		builder.isEquals()
	}

	static mapping = {
		id composite: ["ruolo", "progressivo"]
		version false
	}

	static constraints = {
		dati nullable: true, maxSize: 2000
	}
}
