package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class SuccessioniEredi implements Serializable {

	Long successione
	Integer progressivo
	Short progrErede
	String categoria
	String codFiscale
	String cognome
	String nome
	String denominazione
	String sesso
	String cittaNas
	String provNas
	Date dataNas
	String cittaRes
	String provRes
	String indirizzo
	Long pratica

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append successione
		builder.append progressivo
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append successione, other.successione
		builder.append progressivo, other.progressivo
		builder.isEquals()
	}

	static mapping = {
		id composite: ["successione", "progressivo"]
		version false
		dataNas	sqlType:'Date', column:'DATA_NAS'
	}

	static constraints = {
		categoria nullable: true, maxSize: 1
		codFiscale nullable: true, maxSize: 16
		cognome nullable: true, maxSize: 25
		nome nullable: true, maxSize: 25
		denominazione nullable: true, maxSize: 50
		sesso nullable: true, maxSize: 1
		cittaNas nullable: true, maxSize: 30
		provNas nullable: true, maxSize: 2
		dataNas nullable: true
		cittaRes nullable: true, maxSize: 30
		provRes nullable: true, maxSize: 2
		indirizzo nullable: true, maxSize: 30
		pratica nullable: true
	}
}
