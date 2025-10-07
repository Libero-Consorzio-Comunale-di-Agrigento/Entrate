package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Moltiplicatore implements Serializable {

	short anno
	CategoriaCatasto categoriaCatasto
	BigDecimal moltiplicatore

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append anno
		builder.append categoriaCatasto.categoriaCatasto
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append anno, other.anno
		builder.append categoriaCatasto.categoriaCatasto, other.categoriaCatasto.categoriaCatasto
		builder.isEquals()
	}

	static mapping = {
		id composite: ["anno", "categoriaCatasto"]
		categoriaCatasto	column: 'categoria_catasto'
		
		table 'moltiplicatori'
		//cache true
		version false
	}

	static constraints = {
		categoriaCatasto maxSize: 3
	}
}
