package it.finmatica.tr4.pratiche

import it.finmatica.tr4.Soggetto

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class FamiliarePratica implements Serializable {

	Soggetto soggetto
	String rapportoPar
	
	static belongsTo = [pratica: PraticaTributo]
	
	static mapping = {
		id 			composite: ["pratica", "soggetto"]
		pratica 	column: "pratica"
		soggetto	column: "ni"
		version 	false
		table 		'familiari_pratica'
	}

	static constraints = {
		rapportoPar nullable: true, maxSize: 2
	}
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append pratica
		builder.append soggetto.id
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append pratica, other.pratica
		builder.append soggetto.id, other.soggetto.id
		builder.isEquals()
	}
}
