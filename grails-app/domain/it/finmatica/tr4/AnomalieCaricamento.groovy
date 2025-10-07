package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class AnomalieCaricamento implements Serializable {

	Long documentoId
	Short sequenza
	Long oggetto
	String datiOggetto
	String cognome
	String nome
	String codFiscale
	String descrizione
	String note

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append documentoId
		builder.append sequenza
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append documentoId, other.documentoId
		builder.append sequenza, other.sequenza
		builder.isEquals()
	}

	static mapping = {
		id composite: ["documentoId", "sequenza"]
		version false
	}

	static constraints = {
		oggetto nullable: true
		datiOggetto nullable: true, maxSize: 1000
		cognome nullable: true, maxSize: 60
		nome nullable: true, maxSize: 36
		codFiscale nullable: true, maxSize: 16
		descrizione nullable: true, maxSize: 100
		note nullable: true, maxSize: 2000
	}
}
