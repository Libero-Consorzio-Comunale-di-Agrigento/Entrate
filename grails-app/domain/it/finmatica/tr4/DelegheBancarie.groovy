package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.tipi.SiNoType
import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class DelegheBancarie implements Serializable {

	String codFiscale
	String tipoTributo
	Integer codAbi
	Integer codCab
	String contoCorrente
	String codControlloCc
	Ad4Utente	utente
	Date lastUpdated
	String note
	String codiceFiscaleInt
	String cognomeNomeInt
	boolean flagDelegaCessata
	Date dataRitiroDelega
	boolean flagRataUnica
	String cinBancario
	String ibanPaese
	Byte ibanCinEuropa

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
		lastUpdated column: "data_variazione", sqlType: 'Date'
		dataRitiroDelega sqlType: 'Date'

		flagDelegaCessata type: SiNoType
		flagRataUnica type: SiNoType

		version false
	}

	static constraints = {
		codFiscale maxSize: 16
		tipoTributo maxSize: 5
		codAbi nullable: true
		codCab nullable: true
		contoCorrente nullable: true, maxSize: 12
		codControlloCc nullable: true, maxSize: 1
		utente nullable: true, maxSize: 8
		note nullable: true, maxSize: 2000
		codiceFiscaleInt nullable: true, maxSize: 16
		cognomeNomeInt nullable: true, maxSize: 60
		flagDelegaCessata nullable: true, maxSize: 1
		dataRitiroDelega nullable: true
		flagRataUnica nullable: true, maxSize: 1
		cinBancario nullable: true, maxSize: 1
		ibanPaese nullable: true, maxSize: 2
		ibanCinEuropa nullable: true
	}
}
