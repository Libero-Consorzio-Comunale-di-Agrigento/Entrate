package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class TipoAliquota implements Serializable {

	TipoTributo tipoTributo
	Integer tipoAliquota
	String descrizione
	
	static hasMany = [aliquote: Aliquota]
	
	static mapping = {
		id composite: ["tipoTributo", "tipoAliquota"]
		tipoTributo column: "tipo_tributo"
		 
		table "tipi_aliquota"
		sort "tipoAliquota"
		version false
		
		aliquote cascade: "all-delete-orphan"
	}

	static constraints = {	
		tipoAliquota 	maxSize:2
		tipoTributo 	maxSize: 5
		descrizione 	maxSize: 60
	}
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tipoTributo.tipoTributo
		builder.append tipoAliquota
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tipoTributo.tipoTributo, other.tipoTributo.tipoTributo
		builder.append tipoAliquota, other.tipoAliquota
		builder.isEquals()
	}
}
