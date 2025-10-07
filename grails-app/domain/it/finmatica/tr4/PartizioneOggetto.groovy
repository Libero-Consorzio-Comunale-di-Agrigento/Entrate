package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class PartizioneOggetto implements Serializable, Comparable<PartizioneOggetto> {

	Long sequenza
	TipoArea tipoArea
	Integer numero
	BigDecimal consistenza
	String note

	static belongsTo = [oggetto: Oggetto]
	static hasMany	= [consistenzeTributo: ConsistenzaTributo]
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append oggetto
		builder.append sequenza
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append oggetto, other.oggetto
		builder.append sequenza, other.sequenza
		builder.isEquals()
	}

	static mapping = {
		id composite: ["oggetto", "sequenza"]
		
		oggetto column: "oggetto"
		tipoArea column: "tipo_area"
		
		table "partizioni_oggetto"
		version false
		
		// in questo modo riesco a cancellare tutti i figli
		consistenzeTributo cascade: "all-delete-orphan"
	}

	static constraints = {
		numero nullable: true
		note nullable: true, maxSize: 2000
	}
	
	int compareTo(PartizioneOggetto obj) {
		oggetto?.id <=> obj?.oggetto?.id?:
		sequenza <=> obj.sequenza
	}
}
