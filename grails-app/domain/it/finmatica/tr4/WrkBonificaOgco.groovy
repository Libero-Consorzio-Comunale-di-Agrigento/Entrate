package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class WrkBonificaOgco implements Serializable {

	String tipoTributo
	String codFiscale
	Long oggettoPraticaRif

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tipoTributo
		builder.append codFiscale
		builder.append oggettoPraticaRif
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tipoTributo, other.tipoTributo
		builder.append codFiscale, other.codFiscale
		builder.append oggettoPraticaRif, other.oggettoPraticaRif
		builder.isEquals()
	}

	static mapping = {
		id composite: ["tipoTributo", "codFiscale", "oggettoPraticaRif"]
		version false
	}

	static constraints = {
		tipoTributo nullable: true, maxSize: 6
		codFiscale nullable: true, maxSize: 16
		oggettoPraticaRif nullable: true
	}
}
