package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class TotaliPraticaView implements Serializable {

	Long pratica
	BigDecimal totaleImposta
	BigDecimal totaleSoprattasse
	BigDecimal totalePenePecuniarie
	BigDecimal totaleInteressi
	BigDecimal totaleVersato

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append pratica
		builder.append totaleImposta
		builder.append totaleSoprattasse
		builder.append totalePenePecuniarie
		builder.append totaleInteressi
		builder.append totaleVersato
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append pratica, other.pratica
		builder.append totaleImposta, other.totaleImposta
		builder.append totaleSoprattasse, other.totaleSoprattasse
		builder.append totalePenePecuniarie, other.totalePenePecuniarie
		builder.append totaleInteressi, other.totaleInteressi
		builder.append totaleVersato, other.totaleVersato
		builder.isEquals()
	}

	static mapping = {
		id composite: ["pratica", "totaleImposta", "totaleSoprattasse", "totalePenePecuniarie", "totaleInteressi", "totaleVersato"]
		version false
	}

	static constraints = {
		totaleImposta nullable: true
		totaleSoprattasse nullable: true
		totalePenePecuniarie nullable: true
		totaleInteressi nullable: true
		totaleVersato nullable: true
	}
}
