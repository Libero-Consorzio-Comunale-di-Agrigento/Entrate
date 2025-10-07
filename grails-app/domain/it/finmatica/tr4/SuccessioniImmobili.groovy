package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class SuccessioniImmobili implements Serializable {

	Long successione
	Integer progressivo
	Short progrImmobile
	BigDecimal numeratoreQuotaDef
	Integer denominatoreQuotaDef
	String diritto
	Short progrParticella
	String catasto
	String sezione
	String foglio
	String particella1
	String particella2
	Short  subalterno1
	String subalterno2
	String denuncia1
	String denuncia2
	Short annoDenuncia
	String natura
	Integer superficieEttari
	BigDecimal superficieMq
	BigDecimal vani
	String indirizzo
	Long oggetto

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
		particella1	column: "particella_1"
		particella2 column: "particella_2"
		subalterno1 column: "subalterno_1"
		subalterno2 column: "subalterno_2"
		denuncia1   column: "denuncia_1"
		denuncia2   column: "denuncia_2"
	}

	static constraints = {
		numeratoreQuotaDef nullable: true, scale: 3
		denominatoreQuotaDef nullable: true
		diritto nullable: true, maxSize: 2
		progrParticella nullable: true
		catasto nullable: true, maxSize: 2
		sezione nullable: true, maxSize: 2
		foglio nullable: true, maxSize: 4
		particella1 nullable: true, maxSize: 5
		particella2 nullable: true, maxSize: 2
		subalterno1 nullable: true
		subalterno2 nullable: true, maxSize: 1
		denuncia1 nullable: true, maxSize: 7
		denuncia2 nullable: true, maxSize: 3
		annoDenuncia nullable: true
		natura nullable: true, maxSize: 3
		superficieEttari nullable: true
		superficieMq nullable: true, scale: 3
		vani nullable: true, scale: 1
		indirizzo nullable: true, maxSize: 40
		oggetto nullable: true
	}
}
