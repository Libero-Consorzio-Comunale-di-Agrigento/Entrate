package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class SpeseIstruttoria implements Serializable {

	String tipoTributo
	Short anno
	BigDecimal daImporto
	BigDecimal aImporto
	BigDecimal spese
	BigDecimal percInsolvenza

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tipoTributo
		builder.append anno
		builder.append daImporto
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tipoTributo, other.tipoTributo
		builder.append anno, other.anno
		builder.append daImporto, other.daImporto
		builder.isEquals()
	}

	static mapping = {
		id composite: ["tipoTributo", "anno", "daImporto"]
		version false
	}

	static constraints = {
		tipoTributo maxSize: 5
		spese nullable: true
		percInsolvenza nullable: true
	}
}
