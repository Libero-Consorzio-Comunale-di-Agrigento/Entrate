package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class RedditiRiferimento implements Serializable {

	Long pratica
	Short sequenza
	BigDecimal reddito
	String tipo

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append pratica
		builder.append sequenza
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append pratica, other.pratica
		builder.append sequenza, other.sequenza
		builder.isEquals()
	}

	static mapping = {
		id composite: ["pratica", "sequenza"]
		version false
	}

	static constraints = {
		reddito nullable: true
		tipo nullable: true, maxSize: 1
	}
}
