package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class TariffaDomestica implements Serializable {

	Short anno
	Byte numeroFamiliari
	BigDecimal tariffaQuotaFissa
	BigDecimal tariffaQuotaVariabile
	BigDecimal tariffaQuotaFissaNoAp
	BigDecimal tariffaQuotaVariabileNoAp
	Short svuotamentiMinimi

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
		table "tariffe_domestiche"
		version false
	}

	static constraints = {
		tariffaQuotaFissa scale: 5
		tariffaQuotaVariabile scale: 5
		tariffaQuotaFissaNoAp nullable: true, scale: 5
		tariffaQuotaVariabileNoAp nullable: true, scale: 5
		svuotamentiMinimi nullable: true
	}
}
