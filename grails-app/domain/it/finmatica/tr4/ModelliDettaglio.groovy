package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class ModelliDettaglio implements Serializable {

	Short modello
	BigDecimal parametroId
	String testo

	static mapping = {
		id composite: ["modello", "parametroId"]
		version false
	}

	static constraints = {
		testo nullable: true, maxSize: 2000
	}
}
