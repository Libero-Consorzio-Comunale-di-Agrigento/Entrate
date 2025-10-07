package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class ImpreseArtiProfessioni implements Serializable {

	Long pratica
	Short sequenza
	String descrizione
	Byte settore

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append pratica
		builder.append sequenza
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append pratica, other.pratica
		builder.append sequenza, other.sequenza
		builder.isEquals()
	}

	static mapping = {
		id composite: ["pratica", "sequenza"]
		version false
	}

	static constraints = {
		descrizione nullable: true, maxSize: 60
		settore nullable: true
	}
}
