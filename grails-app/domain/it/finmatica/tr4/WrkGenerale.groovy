package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class WrkGenerale implements Serializable {

	String tipoTrattamento
	Short anno
	BigDecimal progressivo
	String dati

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tipoTrattamento
		builder.append anno
		builder.append progressivo
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tipoTrattamento, other.tipoTrattamento
		builder.append anno, other.anno
		builder.append progressivo, other.progressivo
		builder.isEquals()
	}

	static mapping = {
		id composite: ["tipoTrattamento", "anno", "progressivo"]
		version false
	}

	static constraints = {
		tipoTrattamento maxSize: 20
		dati nullable: true, maxSize: 2000
	}
}
