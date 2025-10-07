package it.finmatica.tr4

import java.io.Serializable;

import it.finmatica.tr4.tipi.SiNoType

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class ArchivioVieZona implements Serializable {

	ArchivioVie archivioVie
	Short sequenza
	
	Integer daNumCiv
	Integer aNumCiv
	
	boolean flagPari
	boolean flagDispari
	
	Double daChilometro
	Double aChilometro
	String lato
	
	Short daAnno
	Short aAnno
	
	Short codZona
	Short sequenzaZona
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append archivioVie
		builder.append sequenza
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append archivioVie, other.archivioVie
		builder.append sequenza, other.sequenza
		builder.isEquals()
	}

	static mapping = {
		id composite: ["archivioVie", "sequenza"]
		archivioVie column: "cod_via"
		flagPari type: SiNoType
		flagDispari type: SiNoType
		
		table "archivio_vie_zona"
		version false
	}

	static constraints = {
		daNumCiv nullable: true
		aNumCiv nullable: true
		flagPari nullable: true, maxSize: 1
		flagDispari nullable: true, maxSize: 1
		daChilometro nullable: true
		aChilometro nullable: true
		lato nullable: true, maxSize: 1
		daAnno nullable: true
		aAnno nullable: true
	}
	
	def springSecurityService
	static transients = ['springSecurityService']
}
