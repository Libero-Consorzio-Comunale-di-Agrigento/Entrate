package it.finmatica.tr4

import it.finmatica.tr4.commons.TipoOccupazione;

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class LimiteCalcolo implements Serializable {

	Short anno
	Short sequenza
	
	BigDecimal limiteImposta
	BigDecimal limiteViolazione
	BigDecimal limiteRata
	
	TipoTributo tipoTributo
	String gruppoTributo
	TipoOccupazione tipoOccupazione

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tipoTributo.tipoTributo
		builder.append anno
        builder.append sequenza
		builder.toHashCode()
	}

	boolean equals(LimiteCalcolo other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tipoTributo.tipoTributo, other.tipoTributo.tipoTributo
		builder.append anno, other.anno
        builder.append sequenza, other.sequenza
		builder.isEquals()
	}

	static mapping = {
		id composite: ["tipoTributo", "anno", "sequenza"]
		tipoTributo column: "tipo_tributo"
		
		gruppoTributo column: "gruppo_tributo"
        tipoOccupazione enumType: 'string'
		
		table "Limiti_calcolo"
		version false
	}

	static constraints = {
		tipoTributo maxSize: 5
		
		gruppoTributo		nullable: true, maxSize: 10
		tipoOccupazione		nullable: true, maxSize: 1

		limiteImposta		nullable: true
		limiteViolazione	nullable: true
		limiteRata			nullable: true
	}
}
