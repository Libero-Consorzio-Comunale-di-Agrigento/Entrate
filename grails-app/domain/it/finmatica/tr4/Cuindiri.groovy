package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Cuindiri implements Serializable {

	String codice
	Integer chiave
	Short toponimo
	String indirizzo
	String lotto
	String edificio
	String scala
	String interno
	String civico1
	String civico2
	String civico3
	String piano1
	String piano2
	String piano3

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codice
		builder.append chiave
		builder.append toponimo
		builder.append indirizzo
		builder.append lotto
		builder.append edificio
		builder.append scala
		builder.append interno
		builder.append civico1
		builder.append civico2
		builder.append civico3
		builder.append piano1
		builder.append piano2
		builder.append piano3
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codice, other.codice
		builder.append chiave, other.chiave
		builder.append toponimo, other.toponimo
		builder.append indirizzo, other.indirizzo
		builder.append lotto, other.lotto
		builder.append edificio, other.edificio
		builder.append scala, other.scala
		builder.append interno, other.interno
		builder.append civico1, other.civico1
		builder.append civico2, other.civico2
		builder.append civico3, other.civico3
		builder.append piano1, other.piano1
		builder.append piano2, other.piano2
		builder.append piano3, other.piano3
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codice", "chiave", "toponimo", "indirizzo", "lotto", "edificio", "scala", "interno", "civico1", "civico2", "civico3", "piano1", "piano2", "piano3"]
		version false
	}

	static constraints = {
		codice nullable: true, maxSize: 5
		chiave nullable: true
		toponimo nullable: true
		indirizzo nullable: true, maxSize: 50
		lotto nullable: true, maxSize: 2
		edificio nullable: true, maxSize: 2
		scala nullable: true, maxSize: 2
		interno nullable: true, maxSize: 3
		civico1 nullable: true, maxSize: 6
		civico2 nullable: true, maxSize: 6
		civico3 nullable: true, maxSize: 6
		piano1 nullable: true, maxSize: 4
		piano2 nullable: true, maxSize: 4
		piano3 nullable: true, maxSize: 4
	}
}
