package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class CoeffDomesticiArea implements Serializable {

	String area
	Byte numeroFamiliari
	BigDecimal coeffAdattamento
	BigDecimal coeffAdattamentoSup
	BigDecimal coeffProduttivitaMin
	BigDecimal coeffProduttivitaMax
	BigDecimal coeffProduttivitaMed

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append area
		builder.append numeroFamiliari
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append area, other.area
		builder.append numeroFamiliari, other.numeroFamiliari
		builder.isEquals()
	}

	static mapping = {
		id composite: ["area", "numeroFamiliari"]
		version false
	}

	static constraints = {
		area maxSize: 20
		coeffAdattamento scale: 4
		coeffAdattamentoSup nullable: true, scale: 4
		coeffProduttivitaMin scale: 4
		coeffProduttivitaMax nullable: true, scale: 4
		coeffProduttivitaMed scale: 4
	}
}
