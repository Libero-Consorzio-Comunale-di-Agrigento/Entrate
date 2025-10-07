package it.finmatica.tr4

import it.finmatica.tr4.tipi.SiNoType

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class ConsistenzaTributo implements Serializable {

	TipoTributo tipoTributo
	PartizioneOggetto partizioneOggetto
	/*Oggetto oggetto
	Integer sequenza*/
	BigDecimal consistenza
	boolean flagEsenzione

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tipoTributo
		builder.append partizioneOggetto
		//builder.append sequenza
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tipoTributo, other.tipoTributo
		builder.append partizioneOggetto, other.partizioneOggetto
	//	builder.append sequenza, other.sequenza
		builder.isEquals()
	}

	static mapping = {
		id composite: ["tipoTributo", "partizioneOggetto"]
		
		tipoTributo column: "tipo_tributo"
		columns {
			partizioneOggetto {
				column name: "oggetto"
				column name: "sequenza"	
			}
		}
		//oggetto     column: "oggetto"
		flagEsenzione type: SiNoType
		table "consistenze_tributo"
		version false
	}

	static constraints = {
		tipoTributo maxSize: 5
		flagEsenzione nullable: true, maxSize: 1
	}
}
