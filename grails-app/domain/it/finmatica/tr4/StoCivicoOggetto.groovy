package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class StoCivicoOggetto implements Serializable, Comparable<StoCivicoOggetto> {

	Integer sequenza
	String indirizzoLocalita
	ArchivioVie archivioVie
	Integer numCiv
	String suffisso
	StoOggetto oggetto
	
	static belongsTo = [oggetto: StoOggetto]
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append oggetto?.id
		builder.append sequenza
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append oggetto?.id, other.oggetto?.id
		builder.append sequenza, other.sequenza
		builder.isEquals()
	}

	static mapping = {
		id composite: ["oggetto", "sequenza"]
		
		oggetto 	column: "oggetto"
		archivioVie column: "cod_via"
		sequenza 	insertable: false, updateable: false
		
		table 'sto_civici_oggetto'
		version false
	}

	static constraints = {
		indirizzoLocalita	nullable: true, maxSize: 36
		archivioVie 		nullable: true
		numCiv				nullable: true
		suffisso 			nullable: true, maxSize: 5
	}
	
	int compareTo(StoCivicoOggetto obj) {
		oggetto?.id <=> obj?.oggetto?.id?:
		sequenza <=> obj.sequenza
	}
}
