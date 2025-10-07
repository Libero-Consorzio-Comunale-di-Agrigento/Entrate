package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Cufisica implements Serializable {

	String codice
	Integer partita
	String cognome
	String nome
	String indSupplementari
	String codTitolo
	String numeratore
	String denominatore
	String desTitolo
	Boolean sesso
	String dataNascita
	String luogoNascita
	String codFiscale
	String cognomeNomeRic

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codice
		builder.append partita
		builder.append cognome
		builder.append nome
		builder.append indSupplementari
		builder.append codTitolo
		builder.append numeratore
		builder.append denominatore
		builder.append desTitolo
		builder.append sesso
		builder.append dataNascita
		builder.append luogoNascita
		builder.append codFiscale
		builder.append cognomeNomeRic
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codice, other.codice
		builder.append partita, other.partita
		builder.append cognome, other.cognome
		builder.append nome, other.nome
		builder.append indSupplementari, other.indSupplementari
		builder.append codTitolo, other.codTitolo
		builder.append numeratore, other.numeratore
		builder.append denominatore, other.denominatore
		builder.append desTitolo, other.desTitolo
		builder.append sesso, other.sesso
		builder.append dataNascita, other.dataNascita
		builder.append luogoNascita, other.luogoNascita
		builder.append codFiscale, other.codFiscale
		builder.append cognomeNomeRic, other.cognomeNomeRic
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codice", "partita", "cognome", "nome", "indSupplementari", "codTitolo", "numeratore", "denominatore", "desTitolo", "sesso", "dataNascita", "luogoNascita", "codFiscale", "cognomeNomeRic"]
		version false
	}

	static constraints = {
		codice nullable: true, maxSize: 5
		partita nullable: true
		cognome nullable: true, maxSize: 24
		nome nullable: true, maxSize: 20
		indSupplementari nullable: true, maxSize: 75
		codTitolo nullable: true, maxSize: 7
		numeratore nullable: true, maxSize: 9
		denominatore nullable: true, maxSize: 9
		desTitolo nullable: true, maxSize: 25
		sesso nullable: true
		dataNascita nullable: true, maxSize: 10
		luogoNascita nullable: true, maxSize: 25
		codFiscale nullable: true, maxSize: 16
		cognomeNomeRic nullable: true, maxSize: 45
	}
}
