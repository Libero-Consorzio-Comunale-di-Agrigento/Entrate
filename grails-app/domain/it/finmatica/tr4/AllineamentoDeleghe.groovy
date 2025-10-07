package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class AllineamentoDeleghe implements Serializable {

	String codFiscale
	String tipoTributo
	Integer codAbi
	Integer codCab
	String contoCorrente
	String codControlloCc
	String cinBancario
	String ibanPaese
	Byte ibanCinEuropa
	String stato
	Date dataInvio
	Ad4Utente	utente
	Date lastUpdated
	String note
	String codiceFiscaleInt
	String cognomeNomeInt

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codFiscale
		builder.append tipoTributo
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codFiscale, other.codFiscale
		builder.append tipoTributo, other.tipoTributo
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codFiscale", "tipoTributo"]
		utente	column: "utente"
		dataInvio	sqlType: 'Date'
		lastUpdated	column: "data_variazione", sqlType: 'Date'
		version false
	}

	static constraints = {
		codFiscale maxSize: 16
		tipoTributo maxSize: 5
		codAbi nullable: true
		codCab nullable: true
		contoCorrente nullable: true, maxSize: 12
		codControlloCc nullable: true, maxSize: 1
		cinBancario nullable: true, maxSize: 1
		ibanPaese nullable: true, maxSize: 2
		ibanCinEuropa nullable: true
		stato nullable: true, maxSize: 10
		dataInvio nullable: true
		utente nullable: true, maxSize: 8
		lastUpdated nullable: true
		note nullable: true, maxSize: 2000
		codiceFiscaleInt nullable: true, maxSize: 16
		cognomeNomeInt nullable: true, maxSize: 60
	}
}
