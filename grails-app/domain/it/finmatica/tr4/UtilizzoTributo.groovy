package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class UtilizzoTributo implements Serializable {

	TipoTributo tipoTributo
	TipoUtilizzo tipoUtilizzo




	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tipoTributo
		builder.append tipoUtilizzo
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tipoTributo, other.tipoTributo
		builder.append tipoUtilizzo, other.tipoUtilizzo
		builder.isEquals()
	}

	static mapping = {
		id composite: ["tipoTributo", "tipoUtilizzo"]
		
		tipoTributo  column: "tipo_tributo"
		tipoUtilizzo column: "tipo_utilizzo"
		
		table "utilizzi_tributo" 
		version false
	}

	static constraints = {
		tipoTributo maxSize: 5
	}
}
