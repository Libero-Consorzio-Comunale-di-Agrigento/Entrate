package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Sottocategorie implements Serializable {

	Short tributo
	Short categoria
	Short sottocategoria
	String descrizione

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tributo
		builder.append categoria
		builder.append sottocategoria
		builder.append descrizione
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tributo, other.tributo
		builder.append categoria, other.categoria
		builder.append sottocategoria, other.sottocategoria
		builder.append descrizione, other.descrizione
		builder.isEquals()
	}

	static mapping = {
		id composite: ["tributo", "categoria", "sottocategoria", "descrizione"]
		version false
	}

	static constraints = {
		categoria nullable: true
		descrizione maxSize: 100
	}
}
