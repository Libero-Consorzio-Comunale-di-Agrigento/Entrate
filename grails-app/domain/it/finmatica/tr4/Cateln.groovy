package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Cateln implements Serializable {

	String codAzienda
	Long codUtente
	Boolean tipoUtenza
	Boolean codIntestatario
	String cognomeNome
	String codFiscale
	String indirizzoFor
	String scalaFor
	String pianoFor
	String internoFor
	Integer capFor
	String localitaFor
	Byte codProFor
	Short codComFor
	String codCatastale
	String codAmm
	String nominativoRec
	String indirizzoRec
	Integer capRec
	String localitaRec
	String codAttivita

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codAzienda
		builder.append codUtente
		builder.append tipoUtenza
		builder.append codIntestatario
		builder.append cognomeNome
		builder.append codFiscale
		builder.append indirizzoFor
		builder.append scalaFor
		builder.append pianoFor
		builder.append internoFor
		builder.append capFor
		builder.append localitaFor
		builder.append codProFor
		builder.append codComFor
		builder.append codCatastale
		builder.append codAmm
		builder.append nominativoRec
		builder.append indirizzoRec
		builder.append capRec
		builder.append localitaRec
		builder.append codAttivita
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codAzienda, other.codAzienda
		builder.append codUtente, other.codUtente
		builder.append tipoUtenza, other.tipoUtenza
		builder.append codIntestatario, other.codIntestatario
		builder.append cognomeNome, other.cognomeNome
		builder.append codFiscale, other.codFiscale
		builder.append indirizzoFor, other.indirizzoFor
		builder.append scalaFor, other.scalaFor
		builder.append pianoFor, other.pianoFor
		builder.append internoFor, other.internoFor
		builder.append capFor, other.capFor
		builder.append localitaFor, other.localitaFor
		builder.append codProFor, other.codProFor
		builder.append codComFor, other.codComFor
		builder.append codCatastale, other.codCatastale
		builder.append codAmm, other.codAmm
		builder.append nominativoRec, other.nominativoRec
		builder.append indirizzoRec, other.indirizzoRec
		builder.append capRec, other.capRec
		builder.append localitaRec, other.localitaRec
		builder.append codAttivita, other.codAttivita
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codAzienda", "codUtente", "tipoUtenza", "codIntestatario", "cognomeNome", "codFiscale", "indirizzoFor", "scalaFor", "pianoFor", "internoFor", "capFor", "localitaFor", "codProFor", "codComFor", "codCatastale", "codAmm", "nominativoRec", "indirizzoRec", "capRec", "localitaRec", "codAttivita"]
		version false
	}

	static constraints = {
		codAzienda nullable: true, maxSize: 5
		codUtente nullable: true
		tipoUtenza nullable: true
		codIntestatario nullable: true
		cognomeNome nullable: true, maxSize: 35
		codFiscale nullable: true, maxSize: 16
		indirizzoFor nullable: true, maxSize: 24
		scalaFor nullable: true, maxSize: 2
		pianoFor nullable: true, maxSize: 2
		internoFor nullable: true, maxSize: 2
		capFor nullable: true
		localitaFor nullable: true, maxSize: 18
		codProFor nullable: true
		codComFor nullable: true
		codCatastale nullable: true, maxSize: 5
		codAmm nullable: true, maxSize: 4
		nominativoRec nullable: true, maxSize: 20
		indirizzoRec nullable: true, maxSize: 24
		capRec nullable: true
		localitaRec nullable: true, maxSize: 17
		codAttivita nullable: true, maxSize: 5
	}
}
