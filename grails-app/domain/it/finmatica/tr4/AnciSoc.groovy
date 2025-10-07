package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class AnciSoc implements Serializable {

	Integer progrRecord
	Short annoFiscale
	Short concessione
	String ente
	Long progrQuietanza
	String tipoRecord
	String ragioneSociale
	String comune
	String filler

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append progrRecord
		builder.append annoFiscale
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append progrRecord, other.progrRecord
		builder.append annoFiscale, other.annoFiscale
		builder.isEquals()
	}

	static mapping = {
		id composite: ["progrRecord", "annoFiscale"]
		version false
	}

	static constraints = {
		concessione nullable: true
		ente nullable: true, maxSize: 4
		progrQuietanza nullable: true
		tipoRecord maxSize: 1
		ragioneSociale nullable: true, maxSize: 60
		comune nullable: true, maxSize: 25
		filler nullable: true, maxSize: 89
	}
}
