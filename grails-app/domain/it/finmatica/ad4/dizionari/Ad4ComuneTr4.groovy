package it.finmatica.ad4.dizionari

import org.apache.commons.lang.builder.HashCodeBuilder

class Ad4ComuneTr4 implements Serializable {
	Integer 	comune
	Long	 	provinciaStato
	Ad4Comune 	ad4Comune
	
	boolean equals(other) {
		if (!(other instanceof Ad4ComuneTr4)) {
			return false
		}

		other.comune == comune && other.provinciaStato == provinciaStato
	}

	int hashCode() {
		def builder = new HashCodeBuilder()
		if (comune) builder.append(comune)
		if (provinciaStato) builder.append(provinciaStato)
		builder.toHashCode()
	}
	
	static mapping = {
		table 		'ad4_v_comuni_tr4'
		id 			generator: 'assigned', composite: ['comune', 'provinciaStato']
		ad4Comune 	column: 'id_comune'
		version 	false
	}
	
	static constraints = {
		ad4Comune nullable: true
	}
}
