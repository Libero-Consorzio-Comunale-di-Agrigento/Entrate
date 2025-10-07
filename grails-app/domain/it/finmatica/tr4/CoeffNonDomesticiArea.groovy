package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class CoeffNonDomesticiArea implements Serializable {

	Short tributo
	String tipoComune
	String area
	Short categoria
	BigDecimal coeffPotenzialeMin
	BigDecimal coeffPotenzialeMax
	BigDecimal coeffProduzioneMin
	BigDecimal coeffProduzioneMax

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tributo
		builder.append tipoComune
		builder.append area
		builder.append categoria
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tributo, other.tributo
		builder.append tipoComune, other.tipoComune
		builder.append area, other.area
		builder.append categoria, other.categoria
		builder.isEquals()
	}

	static mapping = {
		id composite: ["tributo", "tipoComune", "area", "categoria"]
		version false
	}

	static constraints = {
		tipoComune maxSize: 3
		area maxSize: 20
		coeffPotenzialeMin scale: 4
		coeffPotenzialeMax scale: 4
		coeffProduzioneMin scale: 4
		coeffProduzioneMax scale: 4
	}
}
