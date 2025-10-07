package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class VersamentiIci implements Serializable {

	String codFiscale
	Short anno
	BigDecimal importoVersato
	BigDecimal importoVersatoAcconto

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codFiscale
		builder.append anno
		builder.append importoVersato
		builder.append importoVersatoAcconto
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codFiscale, other.codFiscale
		builder.append anno, other.anno
		builder.append importoVersato, other.importoVersato
		builder.append importoVersatoAcconto, other.importoVersatoAcconto
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codFiscale", "anno", "importoVersato", "importoVersatoAcconto"]
		version false
	}

	static constraints = {
		codFiscale maxSize: 16
		anno nullable: true
		importoVersato nullable: true
		importoVersatoAcconto nullable: true
	}
}
