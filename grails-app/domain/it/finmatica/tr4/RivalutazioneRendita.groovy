package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class RivalutazioneRendita implements Serializable {

	short anno
	TipoOggetto tipoOggetto
	BigDecimal aliquota

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append anno
		builder.append tipoOggetto.tipoOggetto
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append anno, other.anno
		builder.append tipoOggetto.tipoOggetto, other.tipoOggetto.tipoOggetto
		builder.isEquals()
	}

	static mapping = {
		id composite: ["anno", "tipoOggetto"]
		tipoOggetto	column: 'tipo_oggetto'
		
		table "rivalutazioni_rendita"
		version false
	}
}
