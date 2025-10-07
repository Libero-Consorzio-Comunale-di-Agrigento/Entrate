package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class RidImpagati implements Serializable {

	Long documentoId
	BigDecimal fattura
	Long ruolo
	String codFiscale
	Short anno
	String tipoTributo
	BigDecimal importoImpagato
	String causale
	String causaleStorno
	Ad4Utente	utente
	Date lastUpdated
	String note

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append documentoId
		builder.append fattura
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append documentoId, other.documentoId
		builder.append fattura, other.fattura
		builder.isEquals()
	}

	static mapping = {
		id composite: ["documentoId", "fattura"]
		utente	column: "utente"	
		version false
		lastUpdated	sqlType:'Date', column:'data_variazione'
	}

	static constraints = {
		codFiscale maxSize: 16
		anno nullable: true
		tipoTributo nullable: true, maxSize: 5
		importoImpagato nullable: true
		causale nullable: true, maxSize: 100
		causaleStorno nullable: true, maxSize: 100
		utente maxSize: 8
		note nullable: true, maxSize: 2000
	}
}
