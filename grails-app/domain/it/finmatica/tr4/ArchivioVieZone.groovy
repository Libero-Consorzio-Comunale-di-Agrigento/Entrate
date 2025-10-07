package it.finmatica.tr4

import java.io.Serializable;

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class ArchivioVieZone implements Serializable {

	Short codZona
	Short sequenza
	String denominazione
	Short daAnno
	Short aAnno
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codZona
		builder.append sequenza
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codZona, other.codZona
		builder.append sequenza, other.sequenza
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codZona", "sequenza"]
		
		table "archivio_vie_zone"
		version false
	}

	static constraints = {
		denominazione nullable: false, maxSize: 60
		daAnno 	nullable: true
		aAnno nullable: true
	}
	
	def springSecurityService
	static transients = ['springSecurityService']
}
