package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Parametri implements Serializable {

	BigDecimal sessione
	String nomeParametro
	BigDecimal progressivo
	String valore
	Date data

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append sessione
		builder.append nomeParametro
		builder.append progressivo
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append sessione, other.sessione
		builder.append nomeParametro, other.nomeParametro
		builder.append progressivo, other.progressivo
		builder.isEquals()
	}

	static mapping = {
		id composite: ["sessione", "nomeParametro", "progressivo"]
		version false
		data	sqlType:'Date', column:'DATA'
	}

	static constraints = {
		nomeParametro maxSize: 30
		valore nullable: true, maxSize: 2000
		data nullable: true
	}
}
