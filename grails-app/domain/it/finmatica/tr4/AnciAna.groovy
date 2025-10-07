package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class AnciAna implements Serializable {

	Integer progrRecord
	Short annoFiscale
	Short concessione
	String ente
	Long progrQuietanza
	String tipoRecord
	String cognome
	String nome
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
		cognome nullable: true, maxSize: 24
		nome nullable: true, maxSize: 20
		comune nullable: true, maxSize: 25
		filler nullable: true, maxSize: 105
	}
}
