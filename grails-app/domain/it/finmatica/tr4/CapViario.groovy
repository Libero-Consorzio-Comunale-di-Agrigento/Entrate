package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class CapViario implements Serializable {

	Short codProvincia
	Short codComune
	String descrizione
	String siglaProvincia
	Integer cap
	Integer daCap
	Integer aCap
	String capMunicipio
	String note

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codProvincia
		builder.append codComune
		builder.append descrizione
		builder.append siglaProvincia
		builder.append cap
		builder.append daCap
		builder.append aCap
		builder.append capMunicipio
		builder.append note
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codProvincia, other.codProvincia
		builder.append codComune, other.codComune
		builder.append descrizione, other.descrizione
		builder.append siglaProvincia, other.siglaProvincia
		builder.append cap, other.cap
		builder.append daCap, other.daCap
		builder.append aCap, other.aCap
		builder.append capMunicipio, other.capMunicipio
		builder.append note, other.note
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codProvincia", "codComune", "descrizione", "siglaProvincia", "cap", "daCap", "aCap", "capMunicipio", "note"]
		version false
	}

	static constraints = {
		codProvincia nullable: true
		codComune nullable: true
		descrizione nullable: true, maxSize: 30
		siglaProvincia nullable: true, maxSize: 10
		cap nullable: true
		daCap nullable: true
		capMunicipio nullable: true, maxSize: 5
		note nullable: true, maxSize: 2000
		aCap nullable: true
	}
}
