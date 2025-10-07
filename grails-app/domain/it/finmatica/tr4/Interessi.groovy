package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Interessi implements Serializable {

	String tipoTributo
	Short sequenza
	Date dataInizio
	Date dataFine
	BigDecimal aliquota
	String tipoInteresse

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tipoTributo
		builder.append sequenza
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tipoTributo, other.tipoTributo
		builder.append sequenza, other.sequenza
		builder.isEquals()
	}

	static mapping = {
		id composite: ["tipoTributo", "sequenza"]
		dataInizio          sqlType: 'Date'
		dataFine            sqlType: 'Date'
		version false
	}

	static constraints = {
		tipoTributo maxSize: 5
		aliquota scale: 4
		tipoInteresse maxSize: 1
	}
}
