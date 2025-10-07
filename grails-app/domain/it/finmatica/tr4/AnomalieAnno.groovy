package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class AnomalieAnno implements Serializable {

	Byte tipoAnomalia
	Short anno
	Date dataElaborazione
	BigDecimal scarto

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tipoAnomalia
		builder.append anno
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tipoAnomalia, other.tipoAnomalia
		builder.append anno, other.anno
		builder.isEquals()
	}

	static mapping = {
		id composite: ["tipoAnomalia", "anno"]
		dataElaborazione	sqlType: 'Date'
		
		version false
	}

	static constraints = {
		scarto nullable: true, scale: 3
	}
}
