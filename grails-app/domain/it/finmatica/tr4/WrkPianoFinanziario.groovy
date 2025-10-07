package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class WrkPianoFinanziario implements Serializable {

	String codice
	BigDecimal progressivo
	Short anno
	String valore

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codice
		builder.append progressivo
		builder.append anno
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codice, other.codice
		builder.append progressivo, other.progressivo
		builder.append anno, other.anno
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codice", "progressivo", "anno"]
		version false
	}

	static constraints = {
		codice maxSize: 10
		valore nullable: true, maxSize: 100
	}
}
