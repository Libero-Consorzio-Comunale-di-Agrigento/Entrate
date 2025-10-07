package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Addebiti implements Serializable {

	String codFiscale
	String tributo
	String cognomeNomeORagioneSociale
	String abi
	String cab
	String numeroCCorrente
	String codiceControllo
	Ad4Utente	utente
	Date lastUpdated
	String note

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codFiscale
		builder.append tributo
		builder.append cognomeNomeORagioneSociale
		builder.append abi
		builder.append cab
		builder.append numeroCCorrente
		builder.append codiceControllo
		builder.append utente
		builder.append lastUpdated
		builder.append note
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codFiscale, other.codFiscale
		builder.append tributo, other.tributo
		builder.append cognomeNomeORagioneSociale, other.cognomeNomeORagioneSociale
		builder.append abi, other.abi
		builder.append cab, other.cab
		builder.append numeroCCorrente, other.numeroCCorrente
		builder.append codiceControllo, other.codiceControllo
		builder.append utente, other.utente
		builder.append lastUpdated, other.lastUpdated
		builder.append note, other.note
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codFiscale", "tributo", "cognomeNomeORagioneSociale", "abi", "cab", "numeroCCorrente", "codiceControllo", "utente", "lastUpdated", "note"]
		utente	column: "utente"
		version false
		cognomeNomeORagioneSociale	column: "COGNOME_NOME_O_RAGIONE_SOCIALE"
		numeroCCorrente				column: "NUMERO_C_CORRENTE"
		lastUpdated				column: "DATA_VARIAZIONE", sqlType: 'Date'
	}

	static constraints = {
		codFiscale nullable: true, maxSize: 16
		tributo nullable: true, maxSize: 5
		cognomeNomeORagioneSociale nullable: true, maxSize: 60
		abi nullable: true, maxSize: 5
		cab nullable: true, maxSize: 5
		numeroCCorrente nullable: true, maxSize: 12
		codiceControllo nullable: true, maxSize: 1
		utente nullable: true, maxSize: 8
		lastUpdated nullable: true
		note nullable: true, maxSize: 50
	}
}
