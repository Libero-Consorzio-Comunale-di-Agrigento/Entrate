package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Cunonfis implements Serializable {

	String codice
	Integer partita
	String denominazione
	String sede
	String codFiscale
	String codTitolo
	String numeratore
	String denominatore
	String desTitolo
	String denominazioneRic

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codice
		builder.append partita
		builder.append denominazione
		builder.append sede
		builder.append codFiscale
		builder.append codTitolo
		builder.append numeratore
		builder.append denominatore
		builder.append desTitolo
		builder.append denominazioneRic
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codice, other.codice
		builder.append partita, other.partita
		builder.append denominazione, other.denominazione
		builder.append sede, other.sede
		builder.append codFiscale, other.codFiscale
		builder.append codTitolo, other.codTitolo
		builder.append numeratore, other.numeratore
		builder.append denominatore, other.denominatore
		builder.append desTitolo, other.desTitolo
		builder.append denominazioneRic, other.denominazioneRic
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codice", "partita", "denominazione", "sede", "codFiscale", "codTitolo", "numeratore", "denominatore", "desTitolo", "denominazioneRic"]
		version false
	}

	static constraints = {
		codice nullable: true, maxSize: 5
		partita nullable: true
		denominazione nullable: true, maxSize: 100
		sede nullable: true, maxSize: 4
		codFiscale nullable: true, maxSize: 16
		codTitolo nullable: true, maxSize: 7
		numeratore nullable: true, maxSize: 9
		denominatore nullable: true, maxSize: 9
		desTitolo nullable: true, maxSize: 25
		denominazioneRic nullable: true, maxSize: 100
	}
}
