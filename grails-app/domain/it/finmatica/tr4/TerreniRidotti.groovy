package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class TerreniRidotti implements Serializable {

	String codFiscale
	Short anno
	BigDecimal valore
	String note

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codFiscale
		builder.append anno
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codFiscale, other.codFiscale
		builder.append anno, other.anno
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codFiscale", "anno"]
		version false
	}

	static constraints = {
		codFiscale maxSize: 16
		note nullable: true, maxSize: 2000
	}
}
