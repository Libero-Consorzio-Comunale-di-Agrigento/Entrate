package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class TipoQualita implements Serializable {

	String descrizione

	static mapping = {
		id column: "tipo_qualita", generator: "assigned"
		
		table "tipi_qualita"
		version false
	}

	static constraints = {
		descrizione nullable: true, maxSize: 60
	}
}
