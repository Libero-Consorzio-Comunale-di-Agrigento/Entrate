package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class DenominazioneVia implements Serializable {

	ArchivioVie archivioVie
	int progrVia
	String descrizione

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append archivioVie
		builder.append progrVia
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append archivioVie, other.archivioVie
		builder.append progrVia, other.progrVia
		builder.isEquals()
	}

	static mapping = {
		id composite: ["archivioVie", "progrVia"]
		archivioVie column: "cod_via"
		
		table 'denominazioni_via'
		version false
	}

	static constraints = {
		descrizione nullable: true, maxSize: 60
	}
}
