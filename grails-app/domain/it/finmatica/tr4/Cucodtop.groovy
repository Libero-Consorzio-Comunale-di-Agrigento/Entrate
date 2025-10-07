package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Cucodtop implements Serializable {

	Short codice
	String toponimo

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codice
		builder.append toponimo
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codice, other.codice
		builder.append toponimo, other.toponimo
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codice", "toponimo"]
		version false
	}

	static constraints = {
		codice nullable: true
		toponimo nullable: true, maxSize: 16
	}
}
