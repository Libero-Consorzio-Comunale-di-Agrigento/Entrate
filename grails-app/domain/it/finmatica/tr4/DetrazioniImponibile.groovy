package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class DetrazioniImponibile implements Serializable {

	String codFiscale
	Long oggettoPratica
	Short anno
	int daMese
	int aMese
	BigDecimal imponibile
	String flagRiog
	BigDecimal percDetrazione
	BigDecimal detrazione
	BigDecimal detrazioneAcconto
	Ad4Utente	utente
	Date lastUpdated
	String note
	BigDecimal detrazioneRimanente
	BigDecimal detrazioneRimanenteAcconto
	BigDecimal detrazioneRimanenteDAcconto
	BigDecimal detrazioneRimanenteD	
	BigDecimal imponibileD
	BigDecimal detrazioneD
	BigDecimal detrazioneDAcconto

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codFiscale
		builder.append oggettoPratica
		builder.append anno
		builder.append daMese
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codFiscale, other.codFiscale
		builder.append oggettoPratica, other.oggettoPratica
		builder.append anno, other.anno
		builder.append daMese, other.daMese
		builder.isEquals()
	}

	static mapping = {
		id composite: ["codFiscale", "oggettoPratica", "anno", "daMese"]
		lastUpdated column: "data_variazione", sqlType: 'Date'
		utente column: "utente", ignoreNotFound: true
		
		version false
		detrazioneRimanenteD		column: "detrazione_rimanente_d"
		imponibileD					column: "imponibile_d"
		detrazioneD					column: "detrazione_d"
		detrazioneDAcconto			column: "detrazione_d_acconto"
		detrazioneRimanenteDAcconto	column: "detrazione_rimanente_d_acconto"
	}

	static constraints = {
		codFiscale maxSize: 16
		imponibile nullable: true
		flagRiog nullable: true, maxSize: 1
		percDetrazione nullable: true
		detrazione nullable: true
		detrazioneAcconto nullable: true
		utente nullable: true, maxSize: 8
		lastUpdated nullable: true
		note nullable: true, maxSize: 2000
		detrazioneRimanente nullable: true
		detrazioneRimanenteAcconto nullable: true
		detrazioneRimanenteD nullable: true
		detrazioneRimanenteDAcconto nullable: true
		imponibileD nullable: true
		detrazioneD nullable: true
		detrazioneDAcconto nullable: true
	}
}
