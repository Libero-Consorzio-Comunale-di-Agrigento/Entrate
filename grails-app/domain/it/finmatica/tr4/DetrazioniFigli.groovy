package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class DetrazioniFigli implements Serializable {

	String codFiscale
	Short anno
	Byte daMese
	Byte aMese
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
		builder.append daMese
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codFiscale, other.codFiscale
		builder.append anno, other.anno
		builder.append daMese, other.daMese
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codFiscale", "anno", "daMese"]
		lastUpdated column: "data_variazione", sqlType: 'Date'
		utente column: "utente", ignoreNotFound: true
		version false
	}

	static constraints = {
		codFiscale maxSize: 16
		aMese nullable: true
		numeroFigli nullable: true
		detrazione nullable: true
		detrazioneAcconto nullable: true
		utente nullable: true, maxSize: 8
		lastUpdated nullable: true
		note nullable: true, maxSize: 2000
	}
}
