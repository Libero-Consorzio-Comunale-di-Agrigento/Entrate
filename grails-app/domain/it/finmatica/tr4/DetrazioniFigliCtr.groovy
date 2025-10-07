package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class DetrazioniFigliCtr implements Serializable {

	String codFiscale
	Short anno
	Date dataRiferimento
	Byte numeroFigli
	BigDecimal detrazione
	BigDecimal detrazioneAcconto
	Ad4Utente	utente
	Date lastUpdated
	String note

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codFiscale
		builder.append anno
		builder.append dataRiferimento
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codFiscale, other.codFiscale
		builder.append anno, other.anno
		builder.append dataRiferimento, other.dataRiferimento
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codFiscale", "anno", "dataRiferimento"]
		dataRiferimento sqlType: 'Date'
		lastUpdated column: "data_variazione", sqlType: 'Date'
		utente	column: "utente"
		version false
	}

	static constraints = {
		codFiscale maxSize: 16
		numeroFigli nullable: true
		detrazione nullable: true
		detrazioneAcconto nullable: true
		utente nullable: true, maxSize: 8
		lastUpdated nullable: true
		note nullable: true, maxSize: 2000
	}
}
