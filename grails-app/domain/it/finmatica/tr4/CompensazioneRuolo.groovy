package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.pratiche.OggettoPratica
import it.finmatica.tr4.tipi.SiNoType
import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class CompensazioneRuolo implements Serializable {

	Contribuente contribuente
	Short anno
	Ruolo ruolo
	OggettoPratica oggettoPratica
	MotivoCompensazione motivoCompensazione
	BigDecimal compensazione
	Ad4Utente utente
	Date lastUpdated
	String note
	boolean flagAutomatico

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append contribuente.codFiscale
		builder.append anno
		builder.append ruolo.id
		builder.append oggettoPratica.id
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append contribuente.codFiscale, other.contribuente.codFiscale
		builder.append anno, other.anno
		builder.append ruolo.id, other.ruolo.id
		builder.append oggettoPratica.id, other.oggettoPratica.id
		builder.isEquals()
	}

	static mapping = {
		id composite: ["contribuente", "anno", "ruolo", "oggettoPratica"]
		contribuente column: "cod_fiscale"
		ruolo column: "ruolo"
		oggettoPratica column: "oggetto_pratica"
		motivoCompensazione column: "motivo_compensazione"

		flagAutomatico type: SiNoType
		lastUpdated column: "data_variazione", sqlType: 'Date'
		utente column: "utente"

		table "compensazioni_ruolo"
		version false
	}

	static constraints = {

		motivoCompensazione nullable: true
		compensazione nullable: true
		utente nullable: true, maxSize: 8
		lastUpdated nullable: true
		note nullable: true, maxSize: 2000
		flagAutomatico nullable: true, maxSize: 1
	}
}
