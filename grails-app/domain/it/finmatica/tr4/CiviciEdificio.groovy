package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class CiviciEdificio implements Serializable {

	Long edificio
	Short sequenza
	Integer codVia
	Integer numCiv
	String suffisso

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append edificio
		builder.append sequenza
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append edificio, other.edificio
		builder.append sequenza, other.sequenza
		builder.isEquals()
	}

	static mapping = {
		id composite: ["edificio", "sequenza"]
		version false
	}

	static constraints = {
		suffisso nullable: true, maxSize: 5
	}
}
