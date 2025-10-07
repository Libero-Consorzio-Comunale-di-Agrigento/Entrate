package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class NumerazioneFatture implements Serializable {

	Short anno
	Integer numero
	Date dataEmissione

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append anno
		builder.append numero
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append anno, other.anno
		builder.append numero, other.numero
		builder.isEquals()
	}

	static mapping = {
		id composite: ["anno", "numero"]
		version false
		dataEmissione	sqlType:'Date', column:'DATA_EMISSIONE'
	}

	static constraints = {
		dataEmissione nullable: true
	}
}
