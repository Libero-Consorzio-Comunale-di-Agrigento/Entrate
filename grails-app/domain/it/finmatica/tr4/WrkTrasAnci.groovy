package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class WrkTrasAnci implements Serializable {

	BigDecimal anno
	BigDecimal progressivo
	String dati

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append anno
		builder.append progressivo
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append anno, other.anno
		builder.append progressivo, other.progressivo
		builder.isEquals()
	}

	static mapping = {
		id composite: ["anno", "progressivo"]
		version false
	}

	static constraints = {
		dati nullable: true, maxSize: 3000
	}
}
