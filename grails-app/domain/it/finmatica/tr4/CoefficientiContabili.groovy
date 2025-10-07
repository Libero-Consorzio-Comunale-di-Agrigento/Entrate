package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class CoefficientiContabili implements Serializable {

	Short anno
	Short annoCoeff
	BigDecimal coeff

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append anno
		builder.append annoCoeff
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append anno, other.anno
		builder.append annoCoeff, other.annoCoeff
		builder.isEquals()
	}

	static mapping = {
		id composite: ["anno", "annoCoeff"]
		version false
	}

	static constraints = {
		coeff nullable: true
	}
}
