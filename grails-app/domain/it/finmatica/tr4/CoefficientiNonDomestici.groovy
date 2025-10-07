package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class CoefficientiNonDomestici implements Serializable {

	Short tributo
	Short categoria
	Short anno
	BigDecimal coeffPotenziale
	BigDecimal coeffProduzione

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tributo
		builder.append categoria
		builder.append anno
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tributo, other.tributo
		builder.append categoria, other.categoria
		builder.append anno, other.anno
		builder.isEquals()
	}

	static mapping = {
		id composite: ["tributo", "categoria", "anno"]
		version false
	}

	static constraints = {
		coeffPotenziale scale: 4
		coeffProduzione scale: 4
	}
}
