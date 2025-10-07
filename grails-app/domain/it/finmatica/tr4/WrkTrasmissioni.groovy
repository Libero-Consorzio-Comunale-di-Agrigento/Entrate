package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class WrkTrasmissioni implements Serializable {

	String numero
	String dati

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append numero
		builder.append dati
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append numero, other.numero
		builder.append dati, other.dati
		builder.isEquals()
	}

	static mapping = {
		id composite: ["numero", "dati"]
		version false
	}

	static constraints = {
		numero maxSize: 15
		dati nullable: true, maxSize: 4000
	}
}
