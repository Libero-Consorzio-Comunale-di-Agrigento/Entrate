package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class CostiTarsu implements Serializable {

	Short anno
	Short sequenza
	String tipoCosto
	BigDecimal costoFisso
	BigDecimal costoVariabile
	String raggruppamento

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append anno
		builder.append sequenza
		builder.append tipoCosto
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append anno, other.anno
		builder.append sequenza, other.sequenza
		builder.append tipoCosto, other.tipoCosto
		builder.isEquals()
	}

	static mapping = {
		id composite: ["anno", "sequenza", "tipoCosto"]
		version false
	}

	static constraints = {
		sequenza unique: ["anno"]
		tipoCosto maxSize: 8
		costoFisso nullable: true
		costoVariabile nullable: true
		raggruppamento nullable: true, maxSize: 4
	}
}
