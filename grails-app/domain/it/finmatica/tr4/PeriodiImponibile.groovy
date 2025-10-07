package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class PeriodiImponibile implements Serializable {

	Byte daMese
	Short anno
	Long oggettoPratica
	String codFiscale
	int aMese
	BigDecimal imponibile
	String flagRiog
	Ad4Utente	utente
	Date lastUpdated
	String note
	BigDecimal imponibileD

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append daMese
		builder.append anno
		builder.append oggettoPratica
		builder.append codFiscale
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append daMese, other.daMese
		builder.append anno, other.anno
		builder.append oggettoPratica, other.oggettoPratica
		builder.append codFiscale, other.codFiscale
		builder.isEquals()
	}

	static mapping = {
		id composite: ["daMese", "anno", "oggettoPratica", "codFiscale"]
		version false
		imponibileD 					column: "imponibile_d"
		lastUpdated	sqlType:'Date', column: 'data_variazione'
		utente	column: "utente"
	}

	static constraints = {
		codFiscale maxSize: 16
		imponibile nullable: true
		flagRiog nullable: true, maxSize: 1
		utente nullable: true, maxSize: 8
		lastUpdated nullable: true
		note nullable: true, maxSize: 2000
		imponibileD nullable: true
	}
}
