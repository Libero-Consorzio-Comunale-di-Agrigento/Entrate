package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class WrkRiscossioni implements Serializable {

	Long ruolo
	String codFiscale
	String tipoTributo
	Short anno
	Boolean rata
	String cognomeNome
	Integer codAbi
	Integer codCab
	String contoCorrente
	String codControlloCc
	BigDecimal importoTotale
	Date dataScadenza
	Date dataPagamento
	BigDecimal importoVersato

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append ruolo
		builder.append codFiscale
		builder.append tipoTributo
		builder.append anno
		builder.append rata
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append ruolo, other.ruolo
		builder.append codFiscale, other.codFiscale
		builder.append tipoTributo, other.tipoTributo
		builder.append anno, other.anno
		builder.append rata, other.rata
		builder.isEquals()
	}

	static mapping = {
		id composite: ["ruolo", "codFiscale", "tipoTributo", "anno", "rata"]
		version false
		dataScadenza	sqlType:'Date', column:'DATA_SCADENZA'
		dataPagamento	sqlType:'Date', column:'DATA_PAGAMENTO'
	}

	static constraints = {
		codFiscale maxSize: 16
		tipoTributo maxSize: 5
		cognomeNome nullable: true, maxSize: 60
		codAbi nullable: true
		codCab nullable: true
		contoCorrente nullable: true, maxSize: 12
		codControlloCc nullable: true, maxSize: 1
		importoTotale nullable: true
		dataScadenza nullable: true
		dataPagamento nullable: true
		importoVersato nullable: true
	}
}
