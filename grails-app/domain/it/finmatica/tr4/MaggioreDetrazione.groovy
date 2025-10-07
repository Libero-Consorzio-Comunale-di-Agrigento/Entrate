package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class MaggioreDetrazione implements Serializable {

	Contribuente contribuente
	TipoTributo tipoTributo
	Short anno
	int motDetrazione
	BigDecimal detrazione
	String note
	BigDecimal detrazioneAcconto
	BigDecimal detrazioneBase
	String flagDetrazionePossesso
	MotivoDetrazione motivoDetrazione
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append contribuente.codFiscale
		builder.append tipoTributo.tipoTributo
		builder.append anno
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append contribuente.codFiscale, other.contribuente.codFiscale
		builder.append tipoTributo.tipoTributo, other.tipoTributo.tipoTributo
		builder.append anno, other.anno
		builder.isEquals()
	}

	static mapping = {
		id composite: ["contribuente", "tipoTributo", "anno"]
		
		contribuente		column: "cod_fiscale"
		tipoTributo			column: "tipo_tributo"
		motivoDetrazione	column: "id_motivo_detrazione"
		
		table "web_maggiori_detrazioni"
		version false
	}

	static constraints = {
		contribuente 	maxSize: 16
		tipoTributo 	maxSize: 5
		detrazione 		nullable: true
		note 			nullable: true, maxSize: 2000
		detrazioneAcconto 		nullable: true
		detrazioneBase 			nullable: true
		flagDetrazionePossesso	nullable: true, maxSize: 1
	}
}
