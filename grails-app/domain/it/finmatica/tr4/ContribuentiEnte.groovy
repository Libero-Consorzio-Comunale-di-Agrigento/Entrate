package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class ContribuentiEnte implements Serializable {

	String comuneEnte
	String siglaEnte
	String provinciaEnte
	String cognomeNome
	Long ni
	String codSesso
	String sesso
	Integer codContribuente
	Byte codControllo
	String codFiscale
	String presso
	String indirizzo
	String comune
	String telefono
	Date dataNascita
	String comuneNascita
	String rappresentante
	String codFiscaleRap
	String indirizzoRap
	String comuneRap
	String dataOdierna

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append comuneEnte
		builder.append siglaEnte
		builder.append provinciaEnte
		builder.append cognomeNome
		builder.append ni
		builder.append codSesso
		builder.append sesso
		builder.append codContribuente
		builder.append codControllo
		builder.append codFiscale
		builder.append presso
		builder.append indirizzo
		builder.append comune
		builder.append telefono
		builder.append dataNascita
		builder.append comuneNascita
		builder.append rappresentante
		builder.append codFiscaleRap
		builder.append indirizzoRap
		builder.append comuneRap
		builder.append dataOdierna
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append comuneEnte, other.comuneEnte
		builder.append siglaEnte, other.siglaEnte
		builder.append provinciaEnte, other.provinciaEnte
		builder.append cognomeNome, other.cognomeNome
		builder.append ni, other.ni
		builder.append codSesso, other.codSesso
		builder.append sesso, other.sesso
		builder.append codContribuente, other.codContribuente
		builder.append codControllo, other.codControllo
		builder.append codFiscale, other.codFiscale
		builder.append presso, other.presso
		builder.append indirizzo, other.indirizzo
		builder.append comune, other.comune
		builder.append telefono, other.telefono
		builder.append dataNascita, other.dataNascita
		builder.append comuneNascita, other.comuneNascita
		builder.append rappresentante, other.rappresentante
		builder.append codFiscaleRap, other.codFiscaleRap
		builder.append indirizzoRap, other.indirizzoRap
		builder.append comuneRap, other.comuneRap
		builder.append dataOdierna, other.dataOdierna
		builder.isEquals()
	}

	static mapping = {
		id composite: ["comuneEnte", "siglaEnte", "provinciaEnte", "cognomeNome", "ni", "codSesso", "sesso", "codContribuente", "codControllo", "codFiscale", "presso", "indirizzo", "comune", "telefono", "dataNascita", "comuneNascita", "rappresentante", "codFiscaleRap", "indirizzoRap", "comuneRap", "dataOdierna"]
		dataNascita sqlType: 'Date'
		version false
	}

	static constraints = {
		comuneEnte nullable: true, maxSize: 40
		siglaEnte nullable: true, maxSize: 5
		provinciaEnte nullable: true, maxSize: 40
		cognomeNome nullable: true, maxSize: 100
		codSesso nullable: true, maxSize: 1
		sesso nullable: true, maxSize: 7
		codContribuente nullable: true
		codControllo nullable: true
		codFiscale maxSize: 16
		presso nullable: true, maxSize: 108
		indirizzo nullable: true, maxSize: 175
		comune nullable: true, maxSize: 94
		telefono nullable: true
		dataNascita nullable: true
		comuneNascita nullable: true, maxSize: 40
		rappresentante nullable: true, maxSize: 40
		codFiscaleRap nullable: true, maxSize: 16
		indirizzoRap nullable: true, maxSize: 50
		comuneRap nullable: true, maxSize: 51
		dataOdierna nullable: true, maxSize: 10
	}
}
