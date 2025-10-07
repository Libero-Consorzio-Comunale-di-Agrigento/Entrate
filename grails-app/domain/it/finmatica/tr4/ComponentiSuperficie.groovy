package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class ComponentiSuperficie implements Serializable {

	Short anno
	Short numeroFamiliari
	BigDecimal daConsistenza
	BigDecimal aConsistenza

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append anno
		builder.append numeroFamiliari
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append anno, other.anno
		builder.append numeroFamiliari, other.numeroFamiliari
		builder.isEquals()
	}

	static mapping = {
		id composite: ["anno", "numeroFamiliari"]
		version false
	}

	static constraints = {
		daConsistenza nullable: true
		aConsistenza nullable: true
	}
}
