package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class OggettoTributo implements Serializable {

	TipoTributo tipoTributo
	TipoOggetto tipoOggetto

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tipoTributo.tipoTributo
		builder.append tipoOggetto.tipoOggetto
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tipoTributo.tipoTributo, other.tipoTributo
		builder.append tipoOggetto.tipoOggetto, other.tipoOggetto
		builder.isEquals()
	}

	static mapping = {
		id composite: 	["tipoTributo", "tipoOggetto"]
		tipoTributo		column: "tipo_tributo"
		tipoOggetto		column: "tipo_oggetto"
		table "oggetti_tributo"
		version false
	}

	static constraints = {
		tipoTributo maxSize: 5
	}
}
