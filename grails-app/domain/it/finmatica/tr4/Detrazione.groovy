package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Detrazione implements Serializable {

	TipoTributo tipoTributo
	short anno
	BigDecimal detrazioneBase
	BigDecimal detrazione
	BigDecimal aliquota
	BigDecimal detrazioneImponibile
	String flagPertinenze
	BigDecimal detrazioneFiglio
	BigDecimal detrazioneMaxFigli

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tipoTributo
		builder.append anno
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tipoTributo, other.tipoTributo
		builder.append anno, other.anno
		builder.isEquals()
	}

	static mapping = {
		id composite: ["tipoTributo", "anno"]
		tipoTributo column: "tipo_tributo"
		
		table "detrazioni"
		version false
	}

	static constraints = {
		tipoTributo maxSize: 5
		detrazioneBase nullable: true
		detrazione nullable: true
		aliquota nullable: true, scale: 4
		detrazioneImponibile nullable: true
		flagPertinenze nullable: true, maxSize: 1
		detrazioneFiglio nullable: true
		detrazioneMaxFigli nullable: true
	}
}
