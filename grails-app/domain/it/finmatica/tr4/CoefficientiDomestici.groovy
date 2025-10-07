package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class CoefficientiDomestici implements Serializable {

	Short anno
	Byte numeroFamiliari
	BigDecimal coeffAdattamento
	BigDecimal coeffProduttivita
	BigDecimal coeffAdattamentoNoAp
	BigDecimal coeffProduttivitaNoAp

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append anno
		builder.append numeroFamiliari
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append anno, other.anno
		builder.append numeroFamiliari, other.numeroFamiliari
		builder.isEquals()
	}

	static mapping = {
		id composite: ["anno", "numeroFamiliari"]
		version false
	}

	static constraints = {
		coeffAdattamento scale: 4
		coeffProduttivita scale: 4
		coeffAdattamentoNoAp nullable: true, scale: 4
		coeffProduttivitaNoAp nullable: true, scale: 4
	}
}
